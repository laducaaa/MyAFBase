package com.ryanladuca.myafbase.data.afi

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import android.util.Log
import com.ryanladuca.myafbase.data.repository.AfiChunk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.File

data class AfiSearchHit(
    val chunk: AfiChunk,
    val keywordScore: Double,
    val semanticScore: Double,
) {
    val matchKind: AfiMatchKind
        get() = when {
            keywordScore > 0 && semanticScore > 0 -> AfiMatchKind.BOTH
            semanticScore > 0 -> AfiMatchKind.SEMANTIC
            else -> AfiMatchKind.KEYWORD
        }

    val totalScore: Double get() = keywordScore + semanticScore
}

enum class AfiMatchKind { KEYWORD, SEMANTIC, BOTH }

class AfiSearchIndex(context: Context) {
    private val dbFile = File(context.filesDir, "afi_search/search_index.sqlite").apply {
        parentFile?.mkdirs()
    }
    private val mutex = Mutex()
    private var ftsMode: FtsMode = FtsMode.UNKNOWN

    suspend fun rebuildIfNeeded(corpusVersion: String, chunks: List<AfiChunk>, onProgress: ((Double) -> Unit)? = null) =
        withContext(Dispatchers.IO) {
            mutex.withLock {
                openDatabase().use { db ->
                    if (!hasRequiredTables(db)) {
                        rebuild(db, corpusVersion, chunks, onProgress)
                        return@withLock
                    }
                    val existingVersion = metadataValue(db, "corpus_version")
                    val count = chunkCount(db)
                    if (existingVersion == corpusVersion && count == chunks.size) {
                        ftsMode = readFtsMode(db)
                        return@withLock
                    }
                    rebuild(db, corpusVersion, chunks, onProgress)
                }
            }
        }

    suspend fun pendingEmbeddingCount(): Int = withContext(Dispatchers.IO) {
        mutex.withLock {
            openDatabase().use { db ->
                if (!hasChunksTable(db)) return@withLock 0
                pendingEmbeddingCountLocked(db)
            }
        }
    }

    suspend fun backfillEmbeddings(
        batchSize: Int = 256,
        onProgress: ((Double) -> Unit)? = null,
    ) = withContext(Dispatchers.IO) {
        mutex.withLock {
            openDatabase().use { db ->
                if (!hasChunksTable(db)) return@withLock
                val totalPending = pendingEmbeddingCountLocked(db)
                if (totalPending == 0) {
                    onProgress?.invoke(1.0)
                    return@withLock
                }
                var completed = 0
                while (true) {
                    val batch = pendingEmbeddingBatch(db, batchSize)
                    if (batch.isEmpty()) break
                    val texts = batch.map { ftsDocumentText(it) }
                    val vectors = AfiEmbeddingService.embedAll(texts) { done, _ ->
                        val partial = completed + done
                        onProgress?.invoke((partial.toDouble() / totalPending).coerceAtMost(1.0))
                    }
                    db.beginTransaction()
                    try {
                        val statement = db.compileStatement("UPDATE chunks SET embedding = ? WHERE id = ?")
                        batch.forEachIndexed { index, chunk ->
                            val data = if (vectors[index].isEmpty()) EMBEDDING_UNAVAILABLE_SENTINEL else vectors[index]
                            statement.clearBindings()
                            statement.bindBlob(1, data)
                            statement.bindString(2, chunk.id)
                            statement.executeUpdateDelete()
                        }
                        db.setTransactionSuccessful()
                    } finally {
                        db.endTransaction()
                    }
                    completed += batch.size
                    onProgress?.invoke((completed.toDouble() / totalPending).coerceAtMost(1.0))
                }
            }
        }
    }

    suspend fun search(query: String, limit: Int = 12): List<AfiSearchHit> = withContext(Dispatchers.IO) {
        mutex.withLock {
            openDatabase().use { db ->
                if (!hasRequiredTables(db)) return@withLock emptyList()
                val trimmed = query.trim()
                if (trimmed.length < 2) return@withLock emptyList()

                val keywordHits = keywordSearch(db, trimmed, kotlin.math.max(limit * 4, 24))
                val semanticHits = if (hasEmbeddings(db)) {
                    semanticSearch(db, trimmed, kotlin.math.max(limit * 4, 24))
                } else {
                    emptyList()
                }

                val merged = linkedMapOf<String, AfiSearchHit>()
                keywordHits.forEachIndexed { rank, (chunk, _) ->
                    val rrf = 1.0 / (60 + rank + 1)
                    val existing = merged[chunk.id]
                    merged[chunk.id] = if (existing == null) {
                        AfiSearchHit(chunk, rrf, 0.0)
                    } else {
                        existing.copy(keywordScore = existing.keywordScore + rrf)
                    }
                }
                semanticHits.forEachIndexed { rank, (chunk, _) ->
                    val rrf = 1.0 / (60 + rank + 1)
                    val existing = merged[chunk.id]
                    merged[chunk.id] = if (existing == null) {
                        AfiSearchHit(chunk, 0.0, rrf)
                    } else {
                        existing.copy(semanticScore = existing.semanticScore + rrf)
                    }
                }
                merged.values.sortedWith(
                    compareByDescending<AfiSearchHit> { it.totalScore }
                        .thenBy { it.chunk.id },
                ).take(limit)
            }
        }
    }

    private fun openDatabase(): SQLiteDatabase =
        SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.CREATE_IF_NECESSARY)

    private fun rebuild(
        db: SQLiteDatabase,
        corpusVersion: String,
        chunks: List<AfiChunk>,
        onProgress: ((Double) -> Unit)?,
    ) {
        ftsMode = detectFtsMode(db)
        db.beginTransaction()
        try {
            db.execSQL("DROP TABLE IF EXISTS chunks_fts")
            db.execSQL("DROP TABLE IF EXISTS chunks")
            db.execSQL("DROP TABLE IF EXISTS metadata")
            db.execSQL(
                """
                CREATE TABLE chunks (
                    id TEXT PRIMARY KEY NOT NULL,
                    publication_id TEXT NOT NULL,
                    publication TEXT NOT NULL,
                    title TEXT NOT NULL,
                    section TEXT,
                    page INTEGER,
                    text TEXT NOT NULL,
                    embedding BLOB NOT NULL
                )
                """.trimIndent(),
            )
            createFtsTable(db, ftsMode)
            db.execSQL(
                """
                CREATE TABLE metadata (
                    key TEXT PRIMARY KEY NOT NULL,
                    value TEXT NOT NULL
                )
                """.trimIndent(),
            )

            val total = maxOf(chunks.size, 1)
            val chunkInsert = db.compileStatement(
                """
                INSERT INTO chunks (id, publication_id, publication, title, section, page, text, embedding)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """.trimIndent(),
            )
            val ftsInsert = db.compileStatement(
                """
                INSERT INTO chunks_fts (chunk_id, text, publication, title, section)
                VALUES (?, ?, ?, ?, ?)
                """.trimIndent(),
            )

            chunks.forEachIndexed { index, chunk ->
                chunkInsert.clearBindings()
                chunkInsert.bindString(1, chunk.id)
                chunkInsert.bindString(2, chunk.publicationId)
                chunkInsert.bindString(3, chunk.publication)
                chunkInsert.bindString(4, chunk.title)
                if (chunk.section != null) {
                    chunkInsert.bindString(5, chunk.section)
                } else {
                    chunkInsert.bindNull(5)
                }
                chunkInsert.bindLong(6, chunk.page.toLong())
                chunkInsert.bindString(7, chunk.text)
                chunkInsert.bindBlob(8, ByteArray(0))
                chunkInsert.executeInsert()

                ftsInsert.clearBindings()
                ftsInsert.bindString(1, chunk.id)
                ftsInsert.bindString(2, ftsDocumentText(chunk))
                ftsInsert.bindString(3, chunk.publication)
                ftsInsert.bindString(4, chunk.title)
                if (chunk.section != null) {
                    ftsInsert.bindString(5, chunk.section)
                } else {
                    ftsInsert.bindNull(5)
                }
                ftsInsert.executeInsert()

                if (index % 50 == 0 || index == chunks.lastIndex) {
                    onProgress?.invoke((index + 1).toDouble() / total)
                }
            }

            db.execSQL("INSERT INTO metadata (key, value) VALUES (?, ?)", arrayOf("corpus_version", corpusVersion))
            db.execSQL("INSERT INTO metadata (key, value) VALUES (?, ?)", arrayOf("fts_mode", ftsMode.name))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    private fun detectFtsMode(db: SQLiteDatabase): FtsMode {
        if (ftsMode != FtsMode.UNKNOWN) return ftsMode
        return if (canCreateFts5(db)) FtsMode.FTS5 else FtsMode.FTS4
    }

    private fun canCreateFts5(db: SQLiteDatabase): Boolean = runCatching {
        db.execSQL("CREATE VIRTUAL TABLE IF NOT EXISTS fts5_probe USING fts5(text)")
        db.execSQL("DROP TABLE IF EXISTS fts5_probe")
        true
    }.getOrDefault(false)

    private fun createFtsTable(db: SQLiteDatabase, mode: FtsMode) {
        when (mode) {
            FtsMode.FTS5 -> db.execSQL(
                """
                CREATE VIRTUAL TABLE chunks_fts USING fts5(
                    chunk_id UNINDEXED,
                    text,
                    publication,
                    title,
                    section,
                    tokenize = 'porter unicode61'
                )
                """.trimIndent(),
            )
            FtsMode.FTS4 -> db.execSQL(
                """
                CREATE VIRTUAL TABLE chunks_fts USING fts4(
                    chunk_id,
                    text,
                    publication,
                    title,
                    section,
                    tokenize=porter
                )
                """.trimIndent(),
            )
            FtsMode.UNKNOWN -> error("FTS mode not resolved")
        }
    }

    private fun keywordSearch(db: SQLiteDatabase, query: String, limit: Int): List<Pair<AfiChunk, Double>> {
        for (ftsQuery in AfiSearchQueryBuilder.ftsQueries(query)) {
            val hits = runKeywordSearch(db, ftsQuery, limit)
            if (hits.isNotEmpty()) return hits
        }
        return emptyList()
    }

    private fun runKeywordSearch(db: SQLiteDatabase, ftsQuery: String, limit: Int): List<Pair<AfiChunk, Double>> {
        val sql = when (ftsMode) {
            FtsMode.FTS4 -> """
                SELECT c.id, c.publication_id, c.publication, c.title, c.section, c.page, c.text
                FROM chunks_fts
                JOIN chunks c ON c.id = chunks_fts.chunk_id
                WHERE chunks_fts MATCH ?
                LIMIT ?
            """.trimIndent()
            else -> """
                SELECT c.id, c.publication_id, c.publication, c.title, c.section, c.page, c.text,
                       bm25(chunks_fts) AS rank
                FROM chunks_fts
                JOIN chunks c ON c.id = chunks_fts.chunk_id
                WHERE chunks_fts MATCH ?
                ORDER BY rank
                LIMIT ?
            """.trimIndent()
        }
        val results = mutableListOf<Pair<AfiChunk, Double>>()
        return try {
            db.rawQuery(sql, arrayOf(ftsQuery, limit.toString())).use { cursor ->
                var rank = 0
                while (cursor.moveToNext()) {
                    val chunk = readChunk(cursor) ?: continue
                    val score = if (ftsMode == FtsMode.FTS4) {
                        rank += 1
                        1.0 / rank.toDouble()
                    } else {
                        val bm25Rank = cursor.getDouble(7)
                        1.0 / (1.0 + maxOf(0.0, bm25Rank))
                    }
                    results += chunk to score
                }
            }
            results
        } catch (error: SQLiteException) {
            Log.w(TAG, "FTS query failed: $ftsQuery", error)
            emptyList()
        }
    }

    private fun semanticSearch(db: SQLiteDatabase, query: String, limit: Int): List<Pair<AfiChunk, Double>> {
        val queryVector = AfiEmbeddingService.embed(query) ?: return emptyList()
        val sql = """
            SELECT id, publication_id, publication, title, section, page, text, embedding
            FROM chunks
            WHERE length(embedding) > 4
        """.trimIndent()
        val scored = mutableListOf<Pair<AfiChunk, Double>>()
        db.rawQuery(sql, null).use { cursor ->
            while (cursor.moveToNext()) {
                val chunk = readChunk(cursor) ?: continue
                val embedding = cursor.getBlob(7) ?: continue
                if (embedding.contentEquals(EMBEDDING_UNAVAILABLE_SENTINEL)) continue
                val vector = AfiEmbeddingService.deserialize(embedding) ?: continue
                val similarity = AfiEmbeddingMath.cosineSimilarity(queryVector, vector).toDouble()
                if (similarity > 0.2) scored += chunk to similarity
            }
        }
        return scored.sortedWith(compareByDescending<Pair<AfiChunk, Double>> { it.second }.thenBy { it.first.id })
            .take(limit)
    }

    private fun hasChunksTable(db: SQLiteDatabase): Boolean = runCatching {
        db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='chunks'",
            null,
        ).use { it.moveToFirst() }
    }.getOrDefault(false)

    private fun hasRequiredTables(db: SQLiteDatabase): Boolean = runCatching {
        db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('chunks', 'chunks_fts', 'metadata')",
            null,
        ).use { cursor ->
            var count = 0
            while (cursor.moveToNext()) count++
            count == 3
        }
    }.getOrDefault(false)

    private fun hasEmbeddings(db: SQLiteDatabase): Boolean = runCatching {
        db.rawQuery("SELECT 1 FROM chunks WHERE length(embedding) > 4 LIMIT 1", null).use { it.moveToFirst() }
    }.getOrDefault(false)

    private fun pendingEmbeddingCountLocked(db: SQLiteDatabase): Int =
        db.rawQuery("SELECT COUNT(*) FROM chunks WHERE length(embedding) = 0", null).use { cursor ->
            if (cursor.moveToFirst()) cursor.getInt(0) else 0
        }

    private fun pendingEmbeddingBatch(db: SQLiteDatabase, limit: Int): List<AfiChunk> {
        val sql = """
            SELECT id, publication_id, publication, title, section, page, text
            FROM chunks
            WHERE length(embedding) = 0
            LIMIT ?
        """.trimIndent()
        val batch = mutableListOf<AfiChunk>()
        db.rawQuery(sql, arrayOf(limit.toString())).use { cursor ->
            while (cursor.moveToNext()) {
                readChunk(cursor)?.let { batch += it }
            }
        }
        return batch
    }

    private fun chunkCount(db: SQLiteDatabase): Int =
        db.rawQuery("SELECT COUNT(*) FROM chunks", null).use { cursor ->
            if (cursor.moveToFirst()) cursor.getInt(0) else 0
        }

    private fun metadataValue(db: SQLiteDatabase, key: String): String? =
        db.rawQuery("SELECT value FROM metadata WHERE key = ?", arrayOf(key)).use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }

    private fun readFtsMode(db: SQLiteDatabase): FtsMode =
        metadataValue(db, "fts_mode")?.let { runCatching { FtsMode.valueOf(it) }.getOrNull() }
            ?: FtsMode.FTS5

    private fun readChunk(cursor: android.database.Cursor): AfiChunk? = runCatching {
        AfiChunk(
            id = cursor.getString(0),
            publicationId = cursor.getString(1),
            publication = cursor.getString(2),
            title = cursor.getString(3),
            section = cursor.getString(4),
            page = if (cursor.isNull(5)) 0 else cursor.getInt(5),
            text = cursor.getString(6),
        )
    }.getOrNull()

    private fun ftsDocumentText(chunk: AfiChunk): String =
        listOfNotNull(chunk.publication, chunk.title, chunk.section, chunk.text)
            .joinToString("\n")

    private enum class FtsMode { UNKNOWN, FTS5, FTS4 }

    companion object {
        private const val TAG = "AfiSearchIndex"
        private val EMBEDDING_UNAVAILABLE_SENTINEL = byteArrayOf(0)
    }
}
