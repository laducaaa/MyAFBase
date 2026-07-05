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

    // MARK: - Pending WAR quick log

    /// Persisted alongside the notification post so a cold-launched app
    /// (which hasn't subscribed to the notification yet) can still pick up
    /// the request once `ContentView` becomes active — mirrors how base
    /// switches fall back to `didBecomeActiveNotification`.
    private nonisolated static let pendingWARQuickLogTextKey = "pendingWARQuickLogText"
    private nonisolated static let pendingWARQuickLogFlagKey = "pendingWARQuickLogFlag"

    nonisolated static func setPendingWARQuickLog(text: String) {
        UserDefaults.standard.set(text, forKey: pendingWARQuickLogTextKey)
        UserDefaults.standard.set(true, forKey: pendingWARQuickLogFlagKey)
    }

    nonisolated static func consumePendingWARQuickLog() -> String? {
        guard UserDefaults.standard.bool(forKey: pendingWARQuickLogFlagKey) else { return nil }
        let text = UserDefaults.standard.string(forKey: pendingWARQuickLogTextKey) ?? ""
        UserDefaults.standard.set(false, forKey: pendingWARQuickLogFlagKey)
        return text
    }
}

enum AppIntentNotifications {
    static let didSwitchBase = Notification.Name("MyAFBase.appIntent.didSwitchBase")
    static let baseIDKey = "baseID"

    static let didRequestWARQuickLog = Notification.Name("MyAFBase.appIntent.didRequestWARQuickLog")
    static let warQuickLogTextKey = "warQuickLogText"
}
