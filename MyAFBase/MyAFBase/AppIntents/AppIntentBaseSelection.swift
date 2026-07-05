import Foundation

enum AppIntentBaseSelection {
    nonisolated static let selectedBaseKey = "selectedBaseID"
    nonisolated static let specialPayStorageKey = "specialPayEntries"

    nonisolated static func selectedBaseID() -> String? {
        UserDefaults.standard.string(forKey: selectedBaseKey)
    }

    nonisolated static func setSelectedBaseID(_ id: String) {
        UserDefaults.standard.set(id, forKey: selectedBaseKey)
    }
}

enum AppIntentNotifications {
    static let didSwitchBase = Notification.Name("MyAFBase.appIntent.didSwitchBase")
    static let baseIDKey = "baseID"
}
