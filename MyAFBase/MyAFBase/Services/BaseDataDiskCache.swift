import Foundation

struct BaseDataDiskCache: Sendable {
    nonisolated static let shared = BaseDataDiskCache()

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
                .appendingPathComponent("MyAFBase/BaseData", isDirectory: true)
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

    nonisolated func lastFetched(filename: String) -> Date? {
        let timestamp = metadataDefaults.double(forKey: metadataKey(for: filename))
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    nonisolated func isStale(filename: String, maxAge: TimeInterval) -> Bool {
        guard let lastFetched = lastFetched(filename: filename) else { return true }
        return Date().timeIntervalSince(lastFetched) > maxAge
    }

    nonisolated func remove(filename: String) {
        guard let url = resolvedCacheURL(for: filename) else { return }
        try? fileManager.removeItem(at: url)
        metadataDefaults.removeObject(forKey: metadataKey(for: filename))
    }

    nonisolated private func resolvedCacheURL(for filename: String) -> URL? {
        guard !filename.contains(".."),
              !filename.contains("/"),
              !filename.contains("\\") else {
            return nil
        }

        let safeName = (filename as NSString).lastPathComponent
        guard safeName.hasSuffix(".json"),
              safeName.count <= 128 else {
            return nil
        }

        let url = directoryURL
            .appendingPathComponent(safeName, isDirectory: false)
            .standardizedFileURL

        guard url.deletingLastPathComponent() == directoryURL else { return nil }
        return url
    }

    nonisolated private func metadataKey(for filename: String) -> String {
        "baseDataCache.fetched.\((filename as NSString).lastPathComponent)"
    }
}
