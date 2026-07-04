import Foundation

actor AFICorpusStore {
    static let shared = AFICorpusStore()

    private let cache: AFICorpusDiskCache
    private let session: URLSession
    private var cachedCorpus: AFICorpus?
    private var lastSyncAttempt: Date?

    init(
        cache: AFICorpusDiskCache = .shared,
        session: URLSession = .shared
    ) {
        self.cache = cache
        self.session = session
    }

    func loadCorpus() async -> AFICorpus? {
        if let cachedCorpus {
            return cachedCorpus
        }

        let resolved = resolveBestCorpus(
            built: loadBuiltCorpus(),
            remote: await loadRemoteCorpus(force: false),
            bundled: loadBundledCorpus()
        )
        cachedCorpus = resolved
        return resolved
    }

    func ingestCorpusFromBundledPDFs(
        progress: @Sendable (Double, String) -> Void
    ) throws -> AFICorpus {
        let corpus = try AFIPDFCorpusIngester.ingestFromBundle(progress: progress)
        saveBuiltCorpus(corpus)
        cachedCorpus = corpus
        return corpus
    }

    func syncRemoteCorpus(force: Bool = false) async {
        if let remote = await loadRemoteCorpus(force: force) {
            cachedCorpus = resolveBestCorpus(
                built: loadBuiltCorpus(),
                remote: remote,
                bundled: loadBundledCorpus()
            )
        }
    }

    func resetCache() {
        cachedCorpus = nil
    }

    private func loadBuiltCorpus() -> AFICorpus? {
        decodeCorpus(from: cache.read(filename: AFICorpusRemoteConfig.builtCorpusFilename))
    }

    private func saveBuiltCorpus(_ corpus: AFICorpus) {
        guard let data = try? JSONCoding.encoder.encode(corpus) else { return }
        cache.write(data, filename: AFICorpusRemoteConfig.builtCorpusFilename)
    }

    private func loadBundledCorpus() -> AFICorpus? {
        let subdirectories = ["Resources/AFI", "AFI", nil as String?]

        for subdirectory in subdirectories {
            let url: URL?
            if let subdirectory {
                url = Bundle.main.url(forResource: "afi_corpus", withExtension: "json", subdirectory: subdirectory)
            } else {
                url = Bundle.main.url(forResource: "afi_corpus", withExtension: "json")
            }

            if let url,
               let data = try? Data(contentsOf: url),
               let corpus = decodeCorpus(from: data) {
                return corpus
            }
        }

        return nil
    }

    private func loadRemoteCorpus(force: Bool) async -> AFICorpus? {
        let filename = AFICorpusRemoteConfig.corpusFilename
        let shouldFetch = force
            || cache.isStale(filename: filename, maxAge: AFICorpusRemoteConfig.refreshInterval)
            || decodeCorpus(from: cache.read(filename: filename)) == nil

        guard shouldFetch else {
            return decodeCorpus(from: cache.read(filename: filename))
        }

        let now = Date()
        if !force,
           let lastSyncAttempt,
           now.timeIntervalSince(lastSyncAttempt) < 30 {
            return decodeCorpus(from: cache.read(filename: filename))
        }
        lastSyncAttempt = now

        guard let data = await fetchRemoteCorpus(),
              let corpus = decodeCorpus(from: data) else {
            return decodeCorpus(from: cache.read(filename: filename))
        }

        cache.write(data, filename: filename)
        return corpus
    }

    private func fetchRemoteCorpus() async -> Data? {
        var request = URLRequest(url: AFICorpusRemoteConfig.corpusURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            return data
        } catch {
            print("AFICorpusStore: fetch failed: \(error)")
            return nil
        }
    }

    private func decodeCorpus(from data: Data?) -> AFICorpus? {
        guard let data else { return nil }
        return try? JSONCoding.decoder.decode(AFICorpus.self, from: data)
    }

    /// Prefers the most recently generated corpus (ISO-8601 `dataUpdatedAt` compares
    /// lexicographically), so a freshly bundled corpus always beats stale caches from
    /// earlier device parses or remote fetches. Seed corpora always lose to real ones.
    private func resolveBestCorpus(
        built: AFICorpus?,
        remote: AFICorpus?,
        bundled: AFICorpus?
    ) -> AFICorpus? {
        let candidates = [built, remote, bundled].compactMap { $0 }
        guard !candidates.isEmpty else { return nil }

        return candidates.max { lhs, rhs in
            let lhsIsSeed = lhs.version.hasPrefix("seed-")
            let rhsIsSeed = rhs.version.hasPrefix("seed-")
            if lhsIsSeed != rhsIsSeed {
                return lhsIsSeed
            }
            if lhs.dataUpdatedAt != rhs.dataUpdatedAt {
                return lhs.dataUpdatedAt < rhs.dataUpdatedAt
            }
            return lhs.chunks.count < rhs.chunks.count
        }
    }
}
