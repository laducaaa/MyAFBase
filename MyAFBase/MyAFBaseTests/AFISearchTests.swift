import Foundation
import Testing
@testable import MyAFBase

@Suite("AFI Search")
struct AFISearchTests {
    private func makeCorpus() -> AFICorpus {
        AFICorpus(
            version: "test-1",
            dataUpdatedAt: "2026-07-04T00:00:00Z",
            chunks: [
                AFICorpusChunk(
                    id: "leave-p0001-000",
                    publicationID: "leave",
                    publication: "DAFI 36-3003",
                    title: "Military Leave",
                    section: "Chapter 4 · Para 4.1",
                    page: 12,
                    text: "Convalescent leave is authorized when a member requires a period of recovery following illness, injury, or childbirth. The unit commander approves convalescent leave based on medical provider recommendations."
                ),
                AFICorpusChunk(
                    id: "fitness-p0001-000",
                    publicationID: "fitness",
                    publication: "DAFI 36-2905",
                    title: "Fitness Program",
                    section: "Chapter 2 · Para 2.3",
                    page: 8,
                    text: "Members must complete a physical fitness assessment consisting of cardiorespiratory endurance and muscular fitness components. Scores determine the currency of the fitness assessment."
                ),
                AFICorpusChunk(
                    id: "dress-p0001-000",
                    publicationID: "dress-appearance",
                    publication: "DAFI 36-2903",
                    title: "Dress & Appearance",
                    section: "Chapter 3 · Para 3.1",
                    page: 22,
                    text: "Shaving waivers may be issued for medical conditions. Members with an approved shaving waiver will keep facial hair groomed and within standards described in this instruction."
                )
            ]
        )
    }

    private func makeIndex() -> AFISearchIndex {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("afi-search-tests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("index.sqlite", isDirectory: false)
        return AFISearchIndex(databaseURL: url)
    }

    @Test func indexesAndFindsKeywordMatches() async throws {
        let index = makeIndex()
        let corpus = makeCorpus()

        try await index.rebuildIfNeeded(corpus: corpus)

        // Keyword search works before any embeddings exist.
        let results = try await index.search(query: "convalescent leave")
        #expect(!results.isEmpty)
        #expect(results.first?.chunk.publicationID == "leave")

        // Backfill embeddings, then semantic scores may contribute too.
        try await index.backfillEmbeddings(batchSize: 8)
        let pending = try await index.pendingEmbeddingCount()
        #expect(pending == 0)

        let afterBackfill = try await index.search(query: "recovering after surgery")
        // Semantic match quality depends on the on-device model; just verify no crash
        // and keyword queries still work.
        _ = afterBackfill
        let keywordAgain = try await index.search(query: "shaving waiver")
        #expect(keywordAgain.first?.chunk.publicationID == "dress-appearance")
    }

    @Test func rebuildIsIdempotentForSameVersion() async throws {
        let index = makeIndex()
        let corpus = makeCorpus()

        try await index.rebuildIfNeeded(corpus: corpus)
        try await index.rebuildIfNeeded(corpus: corpus)

        let results = try await index.search(query: "fitness assessment")
        #expect(results.first?.chunk.publicationID == "fitness")
    }

    @Test func shortQueriesReturnNothing() async throws {
        let index = makeIndex()
        try await index.rebuildIfNeeded(corpus: makeCorpus())

        let results = try await index.search(query: "a")
        #expect(results.isEmpty)
    }

    @Test func ftsQueryBuilderProducesFallbacks() {
        let queries = AFISearchQueryBuilder.ftsQueries(from: "convalescent leave")
        #expect(queries.count == 3)
        #expect(queries[0].contains("convalescent leave"))
        #expect(queries[1].contains("AND"))
        #expect(queries[2].contains("OR"))
    }

    @Test func embeddingSerializationRoundTrips() {
        let vector: [Float] = [0.25, -1.5, 3.75]
        let data = AFIEmbeddingService.serialize(vector)
        let decoded = AFIEmbeddingService.deserialize(data)
        #expect(decoded == vector)
    }

    @Test func corpusQualityRejectsSeedCorpora() {
        let seed = AFICorpus(version: "seed-1", dataUpdatedAt: "2026-01-01T00:00:00Z", chunks: [])
        #expect(!AFICorpusQuality.isSearchReady(seed))
    }

    // MARK: - Snippets

    @Test func excerptCentersOnFirstMatch() {
        let filler = String(repeating: "lorem ipsum dolor sit amet ", count: 40)
        let text = filler + "Convalescent leave is authorized for recovery. " + filler
        let excerpt = AFISearchSnippet.excerpt(from: text, query: "convalescent leave")

        #expect(excerpt.localizedCaseInsensitiveContains("convalescent leave"))
        #expect(excerpt.hasPrefix("…"))
        #expect(excerpt.hasSuffix("…"))
    }

    @Test func excerptFallsBackToPrefixWithoutMatch() {
        let text = "Members must maintain professional appearance at all times while in uniform."
        let excerpt = AFISearchSnippet.excerpt(from: text, query: "zzzz")
        #expect(excerpt.hasPrefix("Members must"))
    }

    @Test func tokensIgnoreShortWords() {
        let tokens = AFISearchSnippet.tokens(from: "a PT test")
        #expect(tokens == ["pt", "test"])
    }
}
