import Foundation
import Observation

@Observable
final class SpecialPayStore {
    private let storageKey = "specialPayEntries"
    private(set) var entries: [SpecialPayEntry] = []

    init() {
        load()
    }

    func add(_ entry: SpecialPayEntry) {
        entries.append(entry)
        entries.sort { $0.date < $1.date }
        save()
    }

    func remove(id: String) {
        entries.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SpecialPayEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { $0.date < $1.date }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
