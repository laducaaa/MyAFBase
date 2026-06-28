import Foundation

@Observable
final class NotificationDismissalStore {
    private let storageKey: String
    private var dismissedByBase: [String: Set<String>]

    init(storageKey: String = "dismissedNotificationIDs") {
        self.storageKey = storageKey
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            dismissedByBase = decoded.mapValues { Set($0) }
        } else {
            dismissedByBase = [:]
        }
    }

    func isDismissed(baseID: String, notificationID: String) -> Bool {
        dismissedByBase[baseID]?.contains(notificationID) ?? false
    }

    func dismissedIDs(for baseID: String) -> Set<String> {
        dismissedByBase[baseID] ?? []
    }

    func dismiss(baseID: String, notificationID: String) {
        var dismissed = dismissedByBase[baseID] ?? []
        dismissed.insert(notificationID)
        dismissedByBase[baseID] = dismissed
        persist()
    }

    func dismissAll(baseID: String, notificationIDs: [String]) {
        var dismissed = dismissedByBase[baseID] ?? []
        dismissed.formUnion(notificationIDs)
        dismissedByBase[baseID] = dismissed
        persist()
    }

    private func persist() {
        let encoded = dismissedByBase.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
