package com.ryanladuca.myafbase.data.repository

import android.content.Context
import android.util.Log
import com.ryanladuca.myafbase.data.afi.AfiEmbeddingBackfillWorker
import com.ryanladuca.myafbase.data.afi.AfiMatchKind
import com.ryanladuca.myafbase.data.afi.AfiSearchIndex
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.decodeFromStream
import java.io.InputStream

@Serializable
data class AfiChunk(
    val id: String,
    @SerialName("publication_id") val publicationId: String = "",
    val publication: String = "",
    val title: String = "",
    val section: String? = "",
    val page: Int = 0,
    val text: String = "",
)

data class AfiSearchResult(
    val chunk: AfiChunk,
    val matchKind: AfiMatchKind,
)

data class AfiPreparationFailure(
    val title: String,
    val message: String,
)

@Serializable
private data class AfiCorpus(
    val version: String = "",
    val chunks: List<AfiChunk> = emptyList(),
)

class AfiSearchRepository(
    private val context: Context,
    private val json: Json,
) {
    private val index = AfiSearchIndex(context)
    private val loadMutex = Mutex()
    @Volatile private var loadedVersion: String? = null

    private val _semanticBackfillProgress = MutableStateFlow<Double?>(null)
    val semanticBackfillProgress: StateFlow<Double?> = _semanticBackfillProgress.asStateFlow()

    private val _isIndexing = MutableStateFlow(false)
    val isIndexing: StateFlow<Boolean> = _isIndexing.asStateFlow()

    private val _indexProgress = MutableStateFlow(0.0)
    val indexProgress: StateFlow<Double> = _indexProgress.asStateFlow()

    private val _isReady = MutableStateFlow(false)
    val isReady: StateFlow<Boolean> = _isReady.asStateFlow()

    private val _preparationFailure = MutableStateFlow<AfiPreparationFailure?>(null)
    val preparationFailure: StateFlow<AfiPreparationFailure?> = _preparationFailure.asStateFlow()

    suspend fun ensureLoaded() = withContext(Dispatchers.IO) {
        if (_isReady.value) return@withContext
        loadMutex.withLock {
            if (_isReady.value) return@withLock
            _isIndexing.value = true
            _preparationFailure.value = null
            _indexProgress.value = 0.0
            try {
                val corpus = loadCorpus()
                if (corpus.chunks.isEmpty()) {
                    throw IllegalStateException("AFI corpus is empty.")
                }
                index.rebuildIfNeeded(corpus.version, corpus.chunks) { progress ->
                    _indexProgress.value = progress
                }
                loadedVersion = corpus.version
                _isReady.value = true
                _indexProgress.value = 1.0
                if (index.pendingEmbeddingCount() > 0) {
                    AfiEmbeddingBackfillWorker.enqueue(context)
                }
            } catch (error: Exception) {
                Log.e(TAG, "AFI index preparation failed", error)
                loadedVersion = null
                _isReady.value = false
                _preparationFailure.value = AfiPreparationFailure(
                    title = "Could not prepare offline search",
                    message = error.message ?: "An unexpected error occurred while building the search index.",
                )
            } finally {
                _isIndexing.value = false
            }
        }
    }

    suspend fun retryPreparation() {
        _isReady.value = false
        loadedVersion = null
        ensureLoaded()
    }

    suspend fun runEmbeddingBackfill() {
        ensureLoaded()
        if (!_isReady.value) return
        _semanticBackfillProgress.value = 0.0
        try {
            index.backfillEmbeddings { progress ->
                _semanticBackfillProgress.value = progress
            }
        } finally {
            _semanticBackfillProgress.value = null
        }
    }

    suspend fun search(query: String, limit: Int = 12): List<AfiSearchResult> = withContext(Dispatchers.Default) {
        if (!_isReady.value) {
            ensureLoaded()
            if (!_isReady.value) return@withContext emptyList()
        }
        val q = query.trim()
        if (q.length < 2) return@withContext emptyList()
        runCatching {
            index.search(q, limit).map { hit ->
                AfiSearchResult(hit.chunk, hit.matchKind)
            }
        }.getOrElse { error ->
            Log.w(TAG, "AFI search failed for query=$q", error)
            emptyList()
        }
    }

    suspend fun keywordSearch(query: String, limit: Int = 12): List<AfiChunk> =
        search(query, limit).map { it.chunk }

    private fun loadCorpus(): AfiCorpus {
        context.assets.open("afi/afi_corpus.json").use { stream ->
            val corpus = decodeCorpus(stream)
            return corpus.copy(
                chunks = corpus.chunks.map { chunk ->
                    chunk.copy(section = chunk.section?.takeIf { it.isNotBlank() })
                },
            )
        }
    }

    @OptIn(ExperimentalSerializationApi::class)
    private fun decodeCorpus(stream: InputStream): AfiCorpus =
        json.decodeFromStream<AfiCorpus>(stream)

    companion object {
        private const val TAG = "AfiSearchRepository"
    }
}
