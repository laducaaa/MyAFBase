import Foundation

struct BaseDataDiskCache: Sendable {
    static let shared = BaseDataDiskCache()

    private let fileManager: FileManager
    private let directoryURL: URL
    private let metadataDefaults: UserDefaults

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil,
        metadataDefaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.metadataDefaults = metadataDefaults

        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.directoryURL = appSupport.appendingPathComponent("MyAFBase/BaseData", isDirectory: true)
        }

        try? fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    func read(filename: String) -> Data? {
        let url = directoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    func write(_ data: Data, filename: String) {
        let url = directoryURL.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
        metadataDefaults.set(Date().timeIntervalSince1970, forKey: metadataKey(for: filename))
    }

    func lastFetched(filename: String) -> Date? {
        let timestamp = metadataDefaults.double(forKey: metadataKey(for: filename))
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    func isStale(filename: String, maxAge: TimeInterval) -> Bool {
        guard let lastFetched = lastFetched(filename: filename) else { return true }
        return Date().timeIntervalSince(lastFetched) > maxAge
    }

    func remove(filename: String) {
        let url = directoryURL.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
        metadataDefaults.removeObject(forKey: metadataKey(for: filename))
    }

    private func metadataKey(for filename: String) -> String {
        "baseDataCache.fetched.\(filename)"
    }
}
