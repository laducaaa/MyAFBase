import Foundation

actor LocalJSONDataService: BaseDataProviding {
    /// Safe to access from any context: actor `static let` values for `Sendable`
    /// types are treated as global constants, not actor-isolated state.
    static let shared = LocalJSONDataService()

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

        let entries: [BaseIndexEntry]?
        do {
            let data = try Data(contentsOf: url)
            entries = try JSONCoding.decoder.decode([BaseIndexEntry].self, from: data)
        } catch {
            print("LocalJSONDataService: failed to load \(url.lastPathComponent): \(error)")
            entries = nil
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

        let base: Base?
        do {
            let data = try Data(contentsOf: url)
            base = await JSONCoding.decodeBase(from: data)
        } catch {
            print("LocalJSONDataService: failed to load \(url.lastPathComponent): \(error)")
            base = nil
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
