import Foundation

actor RemoteAwareBaseDataService: BaseDataProviding {
    private let bundled: LocalJSONDataService
    private let cache: BaseDataDiskCache
    private let session: URLSession

    private var cachedIndex: [BaseIndexEntry]?
    private var cachedBases: [String: Base] = [:]
    private var lastIndexSyncAttempt: Date?

    init(
        bundled: LocalJSONDataService = LocalJSONDataService(),
        cache: BaseDataDiskCache = .shared,
        session: URLSession = .shared
    ) {
        self.bundled = bundled
        self.cache = cache
        self.session = session
    }

    func syncRemoteUpdates(force: Bool = false, baseID: String? = nil) async {
        await syncRemoteIndex(force: force)

        if let baseID {
            cachedBases.removeValue(forKey: baseID)
            _ = await loadRemoteBase(id: baseID, force: force)
        }
    }

    func loadBaseIndex() async -> [BaseIndexEntry] {
        await mergedIndex()
    }

    func loadPickerBaseIndex() async -> [BaseIndexEntry] {
        BaseCatalog.pickerEntries(from: await mergedIndex())
    }

    func loadBase(id: String) async -> Base? {
        if let cached = cachedBases[id] {
            return cached
        }

        async let remoteBase = loadRemoteBase(id: id, force: false)
        async let bundledBase = bundled.loadBase(id: id)

        let resolved = Self.preferredBase(remote: await remoteBase, bundled: await bundledBase)
        if let resolved {
            cachedBases[id] = resolved
        }
        return resolved
    }

    private func mergedIndex() async -> [BaseIndexEntry] {
        if let cachedIndex {
            return cachedIndex
        }

        await syncRemoteIndex(force: false)

        var indexByID: [String: BaseIndexEntry] = [:]
        for entry in await bundled.loadBaseIndex() {
            indexByID[entry.id] = entry
        }

        if let remoteEntries = decodeIndex(from: cache.read(filename: "bases_index.json")) {
            for entry in remoteEntries {
                indexByID[entry.id] = entry
            }
        }

        let sorted = indexByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        cachedIndex = sorted
        return sorted
    }

    private func syncRemoteIndex(force: Bool) async {
        let shouldFetch = force
            || cache.isStale(filename: "bases_index.json", maxAge: BaseDataRemoteConfig.indexRefreshInterval)
            || decodeIndex(from: cache.read(filename: "bases_index.json")) == nil

        guard shouldFetch else { return }

        let now = Date()
        if !force,
           let lastIndexSyncAttempt,
           now.timeIntervalSince(lastIndexSyncAttempt) < 30 {
            return
        }
        lastIndexSyncAttempt = now

        guard let data = await fetchRemoteData(from: BaseDataRemoteConfig.indexURL) else {
            return
        }

        guard decodeIndex(from: data) != nil else {
            print("RemoteAwareBaseDataService: remote bases_index.json failed to decode")
            return
        }

        cache.write(data, filename: "bases_index.json")
        cachedIndex = nil
    }

    private func loadRemoteBase(id: String, force: Bool) async -> Base? {
        let filename = "\(id).json"

        if !force,
           let cachedData = cache.read(filename: filename),
           !cache.isStale(filename: filename, maxAge: BaseDataRemoteConfig.baseRefreshInterval),
           let cachedBase = decodeBase(from: cachedData) {
            return cachedBase
        }

        if let remoteData = await fetchRemoteData(from: BaseDataRemoteConfig.baseURL(id: id)) {
            if let remoteBase = decodeBase(from: remoteData) {
                cache.write(remoteData, filename: filename)
                return remoteBase
            }
            print("RemoteAwareBaseDataService: remote \(filename) failed to decode")
        }

        if let cachedData = cache.read(filename: filename) {
            return decodeBase(from: cachedData)
        }

        return nil
    }

    private func fetchRemoteData(from url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            guard (200 ... 299).contains(http.statusCode) else {
                print("RemoteAwareBaseDataService: HTTP \(http.statusCode) for \(url.lastPathComponent)")
                return nil
            }
            return data
        } catch {
            print("RemoteAwareBaseDataService: fetch failed for \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    private func decodeIndex(from data: Data?) -> [BaseIndexEntry]? {
        guard let data else { return nil }
        return try? JSONCoding.decoder.decode([BaseIndexEntry].self, from: data)
    }

    private func decodeBase(from data: Data) -> Base? {
        try? JSONCoding.decoder.decode(Base.self, from: data)
    }

    private static func preferredBase(remote: Base?, bundled: Base?) -> Base? {
        switch (remote, bundled) {
        case (nil, let bundled):
            return bundled
        case (let remote, nil):
            return remote
        case (let remote?, let bundled?):
            let remoteDate = remote.dataUpdatedDate ?? .distantPast
            let bundledDate = bundled.dataUpdatedDate ?? .distantPast
            return remoteDate >= bundledDate ? remote : bundled
        }
    }
}
