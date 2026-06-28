import Foundation

protocol BaseDataProviding {
    func loadBaseIndex() async -> [BaseIndexEntry]
    func loadPickerBaseIndex() async -> [BaseIndexEntry]
    func loadBase(id: String) async -> Base?
    func region(for baseID: String) async -> BaseRegion?
    func syncRemoteUpdates(force: Bool, baseID: String?) async
}

extension BaseDataProviding {
    func region(for baseID: String) async -> BaseRegion? {
        let index = await loadBaseIndex()
        return index.first { $0.id == baseID }?.region
    }

    func syncRemoteUpdates(force: Bool = false, baseID: String? = nil) async {}
}
