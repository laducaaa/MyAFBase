import Foundation

actor RemoteAwareBaseDataService: BaseDataProviding {
    private let bundled: LocalJSONDataService
    private let cache: BaseDataDiskCache
    private let session: URLSession

    private var cachedIndex: [BaseIndexEntry]?
    private var cachedBases: [String: Base] = [:]
    private var lastIndexSyncAttempt: Date?

    init(
        bundled: LocalJSONDataService? = nil,
        cache: BaseDataDiskCache = .shared,
        session: URLSession = .shared
    ) {
        self.bundled = bundled ?? LocalJSONDataService()
        self.cache = cache
        self.session = session
    }

    func syncRemoteUpdates(force: Bool = false, baseID: String? = nil) async {
        if let baseID, BaseIDValidator.sanitize(baseID) == nil {
            return
        }

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
        guard BaseIDValidator.sanitize(id) != nil else { return nil }

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
            for entry in remoteEntries where BaseIDValidator.sanitize(entry.id) != nil {
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
        let indexFilename = "bases_index.json"
        let shouldFetch = force
            || cache.isStale(filename: indexFilename, maxAge: BaseDataRemoteConfig.indexRefreshInterval)
            || decodeIndex(from: cache.read(filename: indexFilename)) == nil

        guard shouldFetch else { return }

        let now = Date()
        if !force,
           let lastIndexSyncAttempt,
           now.timeIntervalSince(lastIndexSyncAttempt) < 30 {
            return
        }
        lastIndexSyncAttempt = now

        guard let data = await fetchRemoteData(from: BaseDataRemoteConfig.indexURL, filename: indexFilename),
              decodeIndex(from: data) != nil else {
            return
        }

        cache.write(data, filename: indexFilename)
        cachedIndex = nil
    }

    private func loadRemoteBase(id: String, force: Bool) async -> Base? {
        guard let filename = BaseIDValidator.cacheFilename(for: id) else { return nil }

        if !force,
           let cachedData = cache.read(filename: filename),
           !cache.isStale(filename: filename, maxAge: BaseDataRemoteConfig.baseRefreshInterval),
           let cachedBase = await decodeBase(from: cachedData, expectedID: id) {
            return cachedBase
        }

        if let remoteURL = BaseDataRemoteConfig.baseURL(id: id),
           let remoteData = await fetchRemoteData(from: remoteURL, filename: filename),
           let remoteBase = await decodeBase(from: remoteData, expectedID: id) {
            cache.write(remoteData, filename: filename)
            return remoteBase
        }

        if let cachedData = cache.read(filename: filename) {
            return await decodeBase(from: cachedData, expectedID: id)
        }

        return nil
    }

    private func fetchRemoteData(from url: URL, filename: String) async -> Data? {
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
            guard BaseDataIntegrity.verify(data: data, filename: filename) else {
                print("RemoteAwareBaseDataService: integrity check failed for \(filename)")
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

    private func decodeBase(from data: Data, expectedID: String) async -> Base? {
        guard let base = await JSONCoding.decodeBase(from: data),
              BaseDataIntegrity.validateBase(base, expectedID: expectedID) else {
            return nil
        }
        return base
    }

    private nonisolated static func preferredBase(remote: Base?, bundled: Base?) -> Base? {
        switch (remote, bundled) {
        case (nil, let bundled):
            return bundled
        case (let remote, nil):
            return remote
        case (let remote?, let bundled?):
            let remoteDate = dataUpdatedDate(for: remote)
            let bundledDate = dataUpdatedDate(for: bundled)
            return remoteDate >= bundledDate ? remote : bundled
        }
    }

    private nonisolated static func dataUpdatedDate(for base: Base) -> Date {
        guard let dataUpdatedAt = base.dataUpdatedAt else { return .distantPast }
        return ISO8601DateFormatter().date(from: dataUpdatedAt) ?? .distantPast
    }
}
