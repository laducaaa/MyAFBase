import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
final class AFISearchService {
    private(set) var isIndexing = false
    private(set) var indexProgress: Double = 0
    private(set) var isReady = false
    private(set) var lastErrorMessage: String?
    private(set) var preparationFailure: AFISearchPreparationFailure?
    private(set) var corpusVersion: String?
    private(set) var statusMessage: String?
    private(set) var estimatedSecondsRemaining: TimeInterval?

    /// Progress of the background semantic-embedding pass (0–1), or nil when idle/done.
    /// Keyword search is fully usable while this runs; "Related" matches improve as it completes.
    private(set) var semanticBackfillProgress: Double?

    private let corpusStore: AFICorpusStore
    private let searchIndex: AFISearchIndex
    private var indexingStartedAt: Date?
    private var backfillTask: Task<Void, Never>?

    #if canImport(UIKit)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif

    init(
        corpusStore: AFICorpusStore = .shared,
        searchIndex: AFISearchIndex = AFISearchIndex()
    ) {
        self.corpusStore = corpusStore
        self.searchIndex = searchIndex
    }

    /// Human-readable estimate for the indexing card, e.g. "About 20 seconds left".
    var estimatedTimeRemainingText: String? {
        guard isIndexing, let seconds = estimatedSecondsRemaining else { return nil }
        if seconds < 8 {
            return "Almost done"
        }
        if seconds < 90 {
            let rounded = max(10, Int((seconds / 10).rounded()) * 10)
            return "About \(rounded) seconds left"
        }
        let minutes = max(2, Int((seconds / 60).rounded()))
        return "About \(minutes) minutes left"
    }

    func prepareIndexIfNeeded() async {
        guard !isIndexing else { return }

        guard var corpus = await corpusStore.loadCorpus() else {
            preparationFailure = AFISearchCopy.corpusUnavailable
            lastErrorMessage = preparationFailure?.message
            isReady = false
            return
        }

        var didParsePDFs = false

        if AFICorpusQuality.needsBundledPDFParse(corpus), !AppRuntime.isPreview {
            beginIndexing(statusMessage: "Reading bundled AFI PDFs…")
            didParsePDFs = true

            do {
                corpus = try await corpusStore.ingestCorpusFromBundledPDFs { progress, message in
                    Task { @MainActor [weak self] in
                        self?.updateProgress(progress * 0.6)
                        self?.statusMessage = message
                    }
                }
            } catch {
                print("AFISearchService: bundled PDF parse failed: \(error)")
                finishIndexing(failure: AFISearchCopy.bundledParseFailure)
                return
            }
        } else if !AFICorpusQuality.isSearchReady(corpus), !AppRuntime.isPreview {
            preparationFailure = AFISearchCopy.bundledParseFailure
            lastErrorMessage = preparationFailure?.message
            isReady = false
            return
        }

        corpusVersion = corpus.version

        if await searchIndex.isReady(for: corpus) {
            finishIndexing(failure: nil)
            scheduleEmbeddingBackfill()
            return
        }

        if isIndexing {
            statusMessage = "Building offline search index…"
        } else {
            beginIndexing(statusMessage: "Building offline search index…")
        }

        let progressBase = didParsePDFs ? 0.6 : 0.0
        let progressSpan = 1.0 - progressBase

        do {
            try await searchIndex.rebuildIfNeeded(corpus: corpus) { progress in
                Task { @MainActor [weak self] in
                    self?.updateProgress(progressBase + (progress * progressSpan))
                }
            }
            finishIndexing(failure: nil)
            scheduleEmbeddingBackfill()
        } catch {
            print("AFISearchService: index build failed: \(error)")
            finishIndexing(failure: AFISearchCopy.indexBuildFailure)
        }
    }

    func retryPreparation() async {
        preparationFailure = nil
        lastErrorMessage = nil
        isReady = false
        statusMessage = nil
        await prepareIndexIfNeeded()
    }

    func syncCorpus() async {
        backfillTask?.cancel()
        await corpusStore.syncRemoteCorpus(force: true)
        await corpusStore.resetCache()
        isReady = false
        await prepareIndexIfNeeded()
    }

    func search(query: String) async -> [AFISearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        if !isReady {
            await prepareIndexIfNeeded()
        }

        guard isReady else { return [] }

        do {
            let hits = try await searchIndex.search(query: trimmed)
            return hits.map { hit in
                let matchKind: AFISearchMatchKind
                if hit.keywordScore > 0, hit.semanticScore > 0 {
                    matchKind = .hybrid
                } else if hit.keywordScore > 0 {
                    matchKind = .keyword
                } else {
                    matchKind = .semantic
                }

                return AFISearchResult(
                    chunk: hit.chunk,
                    score: hit.keywordScore + hit.semanticScore,
                    matchKind: matchKind,
                    pdfURL: pdfURL(for: hit.chunk.publicationID)
                )
            }
        } catch {
            preparationFailure = AFISearchCopy.searchFailed
            lastErrorMessage = preparationFailure?.message
            print("AFISearchService: search failed: \(error)")
            return []
        }
    }

    func pdfURL(for publicationID: String) -> URL? {
        if let bundled = AFICorpusBundledResources.bundledPDFURL(for: publicationID) {
            return bundled
        }

        return EssentialAFIs.stationed.first(where: { $0.id == publicationID })?.url
    }

    // MARK: - Semantic embedding backfill

    /// Fills in semantic embeddings after keyword search is already live. Runs in
    /// batches that each commit separately, so it resumes where it left off if the
    /// app is closed partway through.
    private func scheduleEmbeddingBackfill() {
        guard backfillTask == nil, !AppRuntime.isPreview else { return }

        backfillTask = Task { [weak self] in
            guard let self else { return }

            do {
                let pending = try await self.searchIndex.pendingEmbeddingCount()
                guard pending > 0 else {
                    self.completeEmbeddingBackfill()
                    return
                }

                self.semanticBackfillProgress = 0
                self.updateBackgroundKeepAlive()

                try await self.searchIndex.backfillEmbeddings { progress in
                    Task { @MainActor [weak self] in
                        self?.semanticBackfillProgress = progress
                    }
                }
            } catch {
                print("AFISearchService: embedding backfill interrupted: \(error)")
            }

            self.completeEmbeddingBackfill()
        }
    }

    private func completeEmbeddingBackfill() {
        semanticBackfillProgress = nil
        backfillTask = nil
        updateBackgroundKeepAlive()
    }

    // MARK: - Indexing lifecycle

    private func beginIndexing(statusMessage: String) {
        isIndexing = true
        indexProgress = 0
        estimatedSecondsRemaining = nil
        indexingStartedAt = Date()
        self.statusMessage = statusMessage
        lastErrorMessage = nil
        preparationFailure = nil
        updateBackgroundKeepAlive()
    }

    private func finishIndexing(failure: AFISearchPreparationFailure?) {
        if let failure {
            isReady = false
            preparationFailure = failure
            lastErrorMessage = failure.message
        } else {
            isReady = true
            preparationFailure = nil
            lastErrorMessage = nil
        }
        isIndexing = false
        statusMessage = nil
        estimatedSecondsRemaining = nil
        indexingStartedAt = nil
        updateBackgroundKeepAlive()
    }

    private func updateProgress(_ value: Double) {
        indexProgress = min(max(value, 0), 1)

        guard let startedAt = indexingStartedAt, indexProgress > 0.03 else {
            estimatedSecondsRemaining = nil
            return
        }
        let elapsed = Date().timeIntervalSince(startedAt)
        estimatedSecondsRemaining = max(0, elapsed * (1 - indexProgress) / indexProgress)
    }

    // MARK: - Background keep-alive

    /// Asks iOS for extra runtime while index work is in flight so it can finish if
    /// the user leaves the app. Work commits incrementally, so even if time expires
    /// the next launch resumes instead of starting over.
    private func updateBackgroundKeepAlive() {
        #if canImport(UIKit)
        let needsKeepAlive = isIndexing || backfillTask != nil

        if needsKeepAlive, backgroundTaskID == .invalid {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AFISearchIndexing") { [weak self] in
                Task { @MainActor in
                    self?.releaseBackgroundKeepAlive()
                }
            }
        } else if !needsKeepAlive {
            releaseBackgroundKeepAlive()
        }
        #endif
    }

    private func releaseBackgroundKeepAlive() {
        #if canImport(UIKit)
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        #endif
    }
}
