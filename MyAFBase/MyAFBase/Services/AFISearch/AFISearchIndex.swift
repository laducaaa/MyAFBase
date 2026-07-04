import Foundation
import SQLite3

enum AFISearchIndexError: Error {
    case openFailed
    case prepareFailed
    case executionFailed
    case missingEmbedding
}

actor AFISearchIndex {
    private let databaseURL: URL
    private var database: OpaquePointer?
    private var indexedCorpusVersion: String?

    init(databaseURL: URL? = nil) {
        if let databaseURL {
            self.databaseURL = databaseURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.databaseURL = appSupport
                .appendingPathComponent("MyAFBase/AFISearch", isDirectory: true)
                .appendingPathComponent("search_index.sqlite", isDirectory: false)
        }
    }

    deinit {
        if let database {
            sqlite3_close(database)
        }
    }

    /// Builds the keyword (FTS) index. This is fast — a few seconds even for the full
    /// corpus — and search is usable as soon as it completes. Semantic embeddings are
    /// filled in afterwards via `backfillEmbeddings`.
    func rebuildIfNeeded(corpus: AFICorpus, progress: (@Sendable (Double) -> Void)? = nil) throws {
        try openIfNeeded()

        if indexedCorpusVersion == corpus.version,
           try chunkCount() == corpus.chunks.count {
            return
        }

        try rebuild(corpus: corpus, progress: progress)
        indexedCorpusVersion = corpus.version
    }

    /// Number of chunks that still need a semantic embedding.
    func pendingEmbeddingCount() throws -> Int {
        try openIfNeeded()

        let statement = try prepare("SELECT COUNT(*) FROM chunks WHERE length(embedding) = 0;")
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(statement, 0))
    }

    /// Computes semantic embeddings for chunks that don't have one yet, in parallel
    /// batches. Each batch commits separately, so an interrupted run (app killed,
    /// background time expired) resumes from where it stopped instead of restarting.
    func backfillEmbeddings(
        batchSize: Int = 256,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        try openIfNeeded()

        let totalPending = try pendingEmbeddingCount()
        guard totalPending > 0 else {
            progress?(1)
            return
        }

        var completed = 0

        while true {
            try Task.checkCancellation()

            let batch = try pendingEmbeddingBatch(limit: batchSize)
            guard !batch.isEmpty else { break }

            let texts = batch.map { AFISearchIndex.ftsDocumentText(for: $0) }
            let vectors = await AFIEmbeddingService.embedAll(texts)

            try execute("BEGIN IMMEDIATE TRANSACTION;")
            do {
                let update = try prepare("UPDATE chunks SET embedding = ? WHERE id = ?;")
                defer { sqlite3_finalize(update) }

                for (index, chunk) in batch.enumerated() {
                    // A 1-byte sentinel marks "attempted but unavailable" so failed
                    // chunks aren't retried forever; search safely ignores it.
                    let data = vectors[index].isEmpty
                        ? AFISearchIndex.embeddingUnavailableSentinel
                        : vectors[index]
                    try bindBlob(update, index: 1, data)
                    try bindText(update, index: 2, chunk.id)
                    try stepDone(update)
                    sqlite3_reset(update)
                }

                try execute("COMMIT;")
            } catch {
                try? execute("ROLLBACK;")
                throw error
            }

            completed += batch.count
            progress?(min(1, Double(completed) / Double(totalPending)))
        }
    }

    func search(
        query: String,
        limit: Int = 12
    ) throws -> [(chunk: AFICorpusChunk, keywordScore: Double, semanticScore: Double)] {
        try openIfNeeded()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let keywordHits = try keywordSearch(query: trimmed, limit: max(limit * 4, 24))
        let semanticHits = try semanticSearch(query: trimmed, limit: max(limit * 4, 24))

        var merged: [String: (chunk: AFICorpusChunk, keywordScore: Double, semanticScore: Double)] = [:]

        for (rank, hit) in keywordHits.enumerated() {
            let rrf = 1.0 / Double(60 + rank + 1)
            var entry = merged[hit.chunk.id] ?? (hit.chunk, 0, 0)
            entry.keywordScore += rrf
            merged[hit.chunk.id] = entry
        }

        for (rank, hit) in semanticHits.enumerated() {
            let rrf = 1.0 / Double(60 + rank + 1)
            var entry = merged[hit.chunk.id] ?? (hit.chunk, 0, 0)
            entry.semanticScore += rrf
            merged[hit.chunk.id] = entry
        }

        return merged.values
            .sorted { lhs, rhs in
                let lhsTotal = lhs.keywordScore + lhs.semanticScore
                let rhsTotal = rhs.keywordScore + rhs.semanticScore
                if lhsTotal == rhsTotal {
                    return lhs.chunk.id < rhs.chunk.id
                }
                return lhsTotal > rhsTotal
            }
            .prefix(limit)
            .map { $0 }
    }

    func isReady(for corpus: AFICorpus) -> Bool {
        do {
            try openIfNeeded()
            guard indexedCorpusVersion == corpus.version else { return false }
            return try chunkCount() == corpus.chunks.count
        } catch {
            return false
        }
    }

    // MARK: - Private

    private func openIfNeeded() throws {
        if database != nil { return }

        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var handle: OpaquePointer?
        guard sqlite3_open(databaseURL.path, &handle) == SQLITE_OK,
              let handle else {
            throw AFISearchIndexError.openFailed
        }

        database = handle
        try execute("PRAGMA journal_mode=WAL;")
        try execute("PRAGMA synchronous=NORMAL;")

        // On a fresh database the metadata table doesn't exist yet; treat that as
        // "no index built" rather than a failure.
        if let version = (try? metadataValue(for: "corpus_version")) ?? nil {
            indexedCorpusVersion = version
        }
    }

    private func rebuild(
        corpus: AFICorpus,
        progress: (@Sendable (Double) -> Void)? = nil
    ) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION;")

        do {
            try execute("DROP TABLE IF EXISTS chunks_fts;")
            try execute("DROP TABLE IF EXISTS chunks;")
            try execute("DROP TABLE IF EXISTS metadata;")

            try execute(
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
                );
                """
            )

            try execute(
                """
                CREATE VIRTUAL TABLE chunks_fts USING fts5(
                    chunk_id UNINDEXED,
                    text,
                    publication,
                    title,
                    section,
                    tokenize = 'porter unicode61'
                );
                """
            )

            try execute(
                """
                CREATE TABLE metadata (
                    key TEXT PRIMARY KEY NOT NULL,
                    value TEXT NOT NULL
                );
                """
            )

            let insertChunkSQL = """
                INSERT INTO chunks (id, publication_id, publication, title, section, page, text, embedding)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?);
                """
            let insertFTSSQL = """
                INSERT INTO chunks_fts (chunk_id, text, publication, title, section)
                VALUES (?, ?, ?, ?, ?);
                """

            let insertChunk = try prepare(insertChunkSQL)
            defer { sqlite3_finalize(insertChunk) }

            let insertFTS = try prepare(insertFTSSQL)
            defer { sqlite3_finalize(insertFTS) }

            let total = Double(max(corpus.chunks.count, 1))

            for (index, chunk) in corpus.chunks.enumerated() {
                // Embeddings start empty and are backfilled asynchronously so keyword
                // search becomes available within seconds.
                let embeddingData = Data()

                try bindText(insertChunk, index: 1, chunk.id)
                try bindText(insertChunk, index: 2, chunk.publicationID)
                try bindText(insertChunk, index: 3, chunk.publication)
                try bindText(insertChunk, index: 4, chunk.title)
                try bindOptionalText(insertChunk, index: 5, chunk.section)
                if let page = chunk.page {
                    sqlite3_bind_int(insertChunk, 6, Int32(page))
                } else {
                    sqlite3_bind_null(insertChunk, 6)
                }
                try bindText(insertChunk, index: 7, chunk.text)
                try bindBlob(insertChunk, index: 8, embeddingData)
                try stepDone(insertChunk)
                sqlite3_reset(insertChunk)

                try bindText(insertFTS, index: 1, chunk.id)
                try bindText(insertFTS, index: 2, AFISearchIndex.ftsDocumentText(for: chunk))
                try bindText(insertFTS, index: 3, chunk.publication)
                try bindText(insertFTS, index: 4, chunk.title)
                try bindOptionalText(insertFTS, index: 5, chunk.section)
                try stepDone(insertFTS)
                sqlite3_reset(insertFTS)

                if index % 25 == 0 || index == corpus.chunks.count - 1 {
                    progress?(Double(index + 1) / total)
                }
            }

            let metadataStatement = try prepare("INSERT INTO metadata (key, value) VALUES (?, ?);")
            defer { sqlite3_finalize(metadataStatement) }
            try bindText(metadataStatement, index: 1, "corpus_version")
            try bindText(metadataStatement, index: 2, corpus.version)
            try stepDone(metadataStatement)

            try execute("COMMIT;")
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    private func keywordSearch(
        query: String,
        limit: Int
    ) throws -> [(chunk: AFICorpusChunk, score: Double)] {
        for ftsQuery in AFISearchQueryBuilder.ftsQueries(from: query) {
            let hits = try runKeywordSearch(ftsQuery: ftsQuery, limit: limit)
            if !hits.isEmpty {
                return hits
            }
        }
        return []
    }

    private func runKeywordSearch(
        ftsQuery: String,
        limit: Int
    ) throws -> [(chunk: AFICorpusChunk, score: Double)] {
        let sql = """
            SELECT
                c.id, c.publication_id, c.publication, c.title, c.section, c.page, c.text,
                bm25(chunks_fts) AS rank
            FROM chunks_fts
            JOIN chunks c ON c.id = chunks_fts.chunk_id
            WHERE chunks_fts MATCH ?
            ORDER BY rank
            LIMIT ?;
            """

        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }

        try bindText(statement, index: 1, ftsQuery)
        sqlite3_bind_int(statement, 2, Int32(limit))

        var results: [(AFICorpusChunk, Double)] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let chunk = try readChunk(from: statement) else { continue }
            let rank = sqlite3_column_double(statement, 7)
            let score = 1.0 / (1.0 + max(0.0, rank))
            results.append((chunk, score))
        }

        return results
    }

    private func semanticSearch(
        query: String,
        limit: Int
    ) throws -> [(chunk: AFICorpusChunk, score: Double)] {
        guard let queryVector = AFIEmbeddingService.embed(query) else { return [] }

        let sql = """
            SELECT id, publication_id, publication, title, section, page, text, embedding
            FROM chunks
            WHERE length(embedding) > 4;
            """

        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }

        var scored: [(AFICorpusChunk, Double)] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let chunk = try readChunk(from: statement),
                  let embeddingData = readBlob(statement, column: 7),
                  !embeddingData.isEmpty,
                  let vector = AFIEmbeddingService.deserialize(embeddingData) else {
                continue
            }

            let similarity = Double(AFIEmbeddingMath.cosineSimilarity(queryVector, vector))
            if similarity > 0.2 {
                scored.append((chunk, similarity))
            }
        }

        return scored
            .sorted {
                if $0.1 == $1.1 { return $0.0.id < $1.0.id }
                return $0.1 > $1.1
            }
            .prefix(limit)
            .map { $0 }
    }

    private static let embeddingUnavailableSentinel = Data([0])

    private func pendingEmbeddingBatch(limit: Int) throws -> [AFICorpusChunk] {
        let sql = """
            SELECT id, publication_id, publication, title, section, page, text
            FROM chunks
            WHERE length(embedding) = 0
            ORDER BY id
            LIMIT ?;
            """

        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(limit))

        var chunks: [AFICorpusChunk] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let chunk = try readChunk(from: statement) {
                chunks.append(chunk)
            }
        }
        return chunks
    }

    private func chunkCount() throws -> Int {
        let statement = try prepare("SELECT COUNT(*) FROM chunks;")
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(statement, 0))
    }

    private func metadataValue(for key: String) throws -> String? {
        let statement = try prepare("SELECT value FROM metadata WHERE key = ? LIMIT 1;")
        defer { sqlite3_finalize(statement) }

        try bindText(statement, index: 1, key)
        guard sqlite3_step(statement) == SQLITE_ROW,
              let cString = sqlite3_column_text(statement, 0) else {
            return nil
        }
        return String(cString: cString)
    }

    private func readChunk(from statement: OpaquePointer?) throws -> AFICorpusChunk? {
        guard let statement,
              let id = readText(statement, column: 0),
              let publicationID = readText(statement, column: 1),
              let publication = readText(statement, column: 2),
              let title = readText(statement, column: 3) else {
            return nil
        }

        let section = readOptionalText(statement, column: 4)
        let page = sqlite3_column_type(statement, 5) == SQLITE_NULL
            ? nil
            : Int(sqlite3_column_int(statement, 5))
        let text = readText(statement, column: 6) ?? ""

        return AFICorpusChunk(
            id: id,
            publicationID: publicationID,
            publication: publication,
            title: title,
            section: section,
            page: page,
            text: text
        )
    }

    private func prepare(_ sql: String) throws -> OpaquePointer? {
        guard let database else { throw AFISearchIndexError.prepareFailed }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            logSQLiteError(context: "prepare: \(sql.prefix(80))")
            throw AFISearchIndexError.prepareFailed
        }
        return statement
    }

    private func execute(_ sql: String) throws {
        guard let database else { throw AFISearchIndexError.executionFailed }
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            logSQLiteError(context: "execute: \(sql.prefix(80))")
            throw AFISearchIndexError.executionFailed
        }
    }

    private func stepDone(_ statement: OpaquePointer?) throws {
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else {
            logSQLiteError(context: "step returned \(result)")
            throw AFISearchIndexError.executionFailed
        }
    }

    private func logSQLiteError(context: String) {
        let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "no database handle"
        print("AFISearchIndex: SQLite error (\(message)) — \(context)")
    }

    private func bindText(_ statement: OpaquePointer?, index: Int32, _ value: String) throws {
        guard sqlite3_bind_text(statement, index, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) == SQLITE_OK else {
            logSQLiteError(context: "bind text at index \(index)")
            throw AFISearchIndexError.executionFailed
        }
    }

    private func bindOptionalText(_ statement: OpaquePointer?, index: Int32, _ value: String?) throws {
        if let value {
            try bindText(statement, index: index, value)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }

    private func bindBlob(_ statement: OpaquePointer?, index: Int32, _ data: Data) throws {
        let result = data.withUnsafeBytes { buffer in
            sqlite3_bind_blob(
                statement,
                index,
                buffer.baseAddress,
                Int32(data.count),
                unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            )
        }
        guard result == SQLITE_OK else {
            throw AFISearchIndexError.executionFailed
        }
    }

    private func readText(_ statement: OpaquePointer?, column: Int32) -> String? {
        guard let statement,
              let cString = sqlite3_column_text(statement, column) else {
            return nil
        }
        return String(cString: cString)
    }

    private func readOptionalText(_ statement: OpaquePointer?, column: Int32) -> String? {
        guard let statement,
              sqlite3_column_type(statement, column) != SQLITE_NULL else {
            return nil
        }
        return readText(statement, column: column)
    }

    private func readBlob(_ statement: OpaquePointer?, column: Int32) -> Data? {
        guard let statement,
              let bytes = sqlite3_column_blob(statement, column) else {
            return nil
        }
        let length = Int(sqlite3_column_bytes(statement, column))
        return Data(bytes: bytes, count: length)
    }

    private static func ftsDocumentText(for chunk: AFICorpusChunk) -> String {
        [chunk.title, chunk.publication, chunk.section, chunk.text]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

enum AFISearchQueryBuilder {
    nonisolated static func ftsQueries(from rawQuery: String) -> [String] {
        let tokens = tokenize(rawQuery)
        guard !tokens.isEmpty else { return [] }

        if tokens.count == 1 {
            return ["\"\(escape(tokens[0]))\"*"]
        }

        let phrase = tokens.map(escape).joined(separator: " ")
        let andClause = tokens.map { "\"\(escape($0))\"*" }.joined(separator: " AND ")
        let orClause = tokens.map { "\"\(escape($0))\"*" }.joined(separator: " OR ")

        return [
            "\"\(phrase)\"*",
            andClause,
            orClause
        ]
    }

    nonisolated private static func tokenize(_ rawQuery: String) -> [String] {
        rawQuery
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
    }

    nonisolated private static func escape(_ token: String) -> String {
        token.replacingOccurrences(of: "\"", with: "")
    }
}
