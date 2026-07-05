import Foundation

/// Optional auto-delete of old WAR entries. Off by default — entries are
/// kept forever unless the user opts in via `WARSettingsStore.autoDeleteEnabled`.
enum WARRetentionService {
    /// Deletes entries older than the configured retention window, for every
    /// base, in one pass. Cheap enough to call on every WAR Tracker launch.
    static func purgeExpiredEntries(store: WARTrackerStore) {
        guard WARSettingsStore.autoDeleteEnabled else { return }

        let years = WARSettingsStore.autoDeleteAfterYears
        guard let cutoff = Calendar.current.date(byAdding: .year, value: -years, to: Date()) else { return }

        for entry in store.allEntries() where entry.date < cutoff {
            store.delete(entry)
        }
    }
}
