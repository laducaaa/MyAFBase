import Foundation

actor LocalJSONDataService: BaseDataProviding {
    private let subdirectories = ["Bases", "Resources/Bases", nil as String?]
    private var cachedIndex: [BaseIndexEntry]?
    private var cachedBases: [String: Base] = [:]

    func loadBaseIndex() async -> [BaseIndexEntry] {
        await loadFullBaseIndex()
    }

    func loadPickerBaseIndex() async -> [BaseIndexEntry] {
        BaseCatalog.pickerEntries(from: await loadFullBaseIndex())
    }

    private func loadFullBaseIndex() async -> [BaseIndexEntry] {
        if let cachedIndex {
            return cachedIndex
        }

        guard let url = urlForResource("bases_index", extension: "json") else {
            print("LocalJSONDataService: bases_index.json not found")
            return []
        }

        let entries = await decodeOnBackground(url: url) { data in
            try JSONCoding.decoder.decode([BaseIndexEntry].self, from: data)
        }

        guard let entries else { return [] }

        let sorted = entries.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        cachedIndex = sorted
        return sorted
    }

    func loadBase(id: String) async -> Base? {
        if let cached = cachedBases[id] {
            return cached
        }

        guard let url = urlForResource(id, extension: "json") else {
            print("LocalJSONDataService: base file \(id).json not found")
            return nil
        }

        let base = await decodeOnBackground(url: url) { data in
            try JSONCoding.decoder.decode(Base.self, from: data)
        }

        if let base {
            cachedBases[id] = base
        }

        return base
    }

    func region(for baseID: String) async -> BaseRegion? {
        let index = await loadBaseIndex()
        return index.first { $0.id == baseID }?.region
    }

    private func decodeOnBackground<T: Sendable>(
        url: URL,
        _ decode: @Sendable @escaping (Data) throws -> T
    ) async -> T? {
        await Task.detached(priority: .userInitiated) {
            do {
                let data = try Data(contentsOf: url)
                return try decode(data)
            } catch {
                print("LocalJSONDataService: failed to load \(url.lastPathComponent): \(error)")
                return nil
            }
        }.value
    }

    private func urlForResource(_ name: String, extension ext: String) -> URL? {
        for subdirectory in subdirectories {
            if let subdirectory,
               let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
            if subdirectory == nil,
               let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}
