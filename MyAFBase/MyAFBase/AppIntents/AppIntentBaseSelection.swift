import Foundation

enum AppIntentBaseSelection {
    static let selectedBaseKey = "selectedBaseID"
    static let specialPayStorageKey = "specialPayEntries"

    static func selectedBaseID() -> String? {
        UserDefaults.standard.string(forKey: selectedBaseKey)
    }

    static func setSelectedBaseID(_ id: String) {
        UserDefaults.standard.set(id, forKey: selectedBaseKey)
    }
}

enum AppIntentNotifications {
    static let didSwitchBase = Notification.Name("MyAFBase.appIntent.didSwitchBase")
    static let baseIDKey = "baseID"
}
