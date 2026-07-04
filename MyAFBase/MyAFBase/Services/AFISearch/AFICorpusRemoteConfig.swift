import Foundation

/// Remote + cache configuration for the AFI search corpus. Mirrors the base-data
/// pattern: bundled JSON ships with the app, a GitHub-hosted copy allows updates
/// between releases.
enum AFICorpusRemoteConfig: Sendable {
    nonisolated static let repository = "laducaaa/MyAFBase"
    nonisolated static let pinnedRef = "main"
    nonisolated static let corpusPath = "MyAFBase/MyAFBase/Resources/AFI/afi_corpus.json"

    /// Cached copy of the remote corpus.
    nonisolated static let corpusFilename = "afi_corpus_remote.json"

    /// Corpus built on-device from bundled PDFs (fallback when JSON is stale/missing).
    nonisolated static let builtCorpusFilename = "afi_corpus_built.json"

    /// Minimum time between automatic remote corpus refreshes.
    nonisolated static let refreshInterval: TimeInterval = 24 * 60 * 60

    nonisolated static var corpusURL: URL {
        URL(string: "https://raw.githubusercontent.com/\(repository)/\(pinnedRef)/\(corpusPath)")!
    }
}

/// Disk cache for AFI corpus JSON, stored under Application Support/MyAFBase/AFISearch.
struct AFICorpusDiskCache: Sendable {
    nonisolated static let shared = AFICorpusDiskCache()

    nonisolated(unsafe) private let fileManager: FileManager
    private let directoryURL: URL
    nonisolated(unsafe) private let metadataDefaults: UserDefaults

    nonisolated init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil,
        metadataDefaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.metadataDefaults = metadataDefaults

        if let directoryURL {
            self.directoryURL = directoryURL.standardizedFileURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.directoryURL = appSupport
                .appendingPathComponent("MyAFBase/AFISearch", isDirectory: true)
                .standardizedFileURL
        }

        try? fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    nonisolated func read(filename: String) -> Data? {
        guard let url = resolvedCacheURL(for: filename) else { return nil }
        return try? Data(contentsOf: url)
    }

    nonisolated func write(_ data: Data, filename: String) {
        guard let url = resolvedCacheURL(for: filename) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        metadataDefaults.set(Date().timeIntervalSince1970, forKey: metadataKey(for: filename))
    }

    nonisolated func isStale(filename: String, maxAge: TimeInterval) -> Bool {
        let timestamp = metadataDefaults.double(forKey: metadataKey(for: filename))
        guard timestamp > 0 else { return true }
        return Date().timeIntervalSince(Date(timeIntervalSince1970: timestamp)) > maxAge
    }

    nonisolated private func resolvedCacheURL(for filename: String) -> URL? {
        guard !filename.contains(".."),
              !filename.contains("/"),
              !filename.contains("\\") else {
            return nil
        }

        let safeName = (filename as NSString).lastPathComponent
        guard safeName.hasSuffix(".json"), safeName.count <= 128 else { return nil }

        let url = directoryURL
            .appendingPathComponent(safeName, isDirectory: false)
            .standardizedFileURL

        guard url.deletingLastPathComponent() == directoryURL else { return nil }
        return url
    }

    nonisolated private func metadataKey(for filename: String) -> String {
        "afiCorpusCache.fetched.\((filename as NSString).lastPathComponent)"
    }
}
