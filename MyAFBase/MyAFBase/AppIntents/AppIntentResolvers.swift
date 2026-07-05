import Foundation
import SwiftData

enum AppIntentPayResolver {
    static func snapshot() async -> PayWidgetSnapshot {
        if let cached = WidgetDataStore.loadPay(), cached.isAvailable {
            return cached
        }

        let specialPays = loadSpecialPays()
        return await MainActor.run {
            PayWidgetBuilder.snapshot(specialPays: specialPays)
        }
    }

    nonisolated static func spokenSummary(from snapshot: PayWidgetSnapshot) -> String {
        guard snapshot.isAvailable else {
            return "No upcoming pay date is available yet. Open the app to refresh your pay calendar."
        }

        if snapshot.daysUntil == 0 {
            return "\(snapshot.nextTitle) is today, \(snapshot.nextDateLabel)."
        }
        if snapshot.daysUntil == 1 {
            return "\(snapshot.nextTitle) is tomorrow, \(snapshot.nextDateLabel)."
        }
        return "\(snapshot.nextTitle) is \(snapshot.nextDateLabel), in \(snapshot.daysUntil) days."
    }

    private static func loadSpecialPays() -> [SpecialPayEntry] {
        guard let data = UserDefaults.standard.data(forKey: AppIntentBaseSelection.specialPayStorageKey),
              let decoded = try? JSONDecoder().decode([SpecialPayEntry].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.date < $1.date }
    }
}

enum AppIntentReminderResolver {
    static func nextActiveReminder() async -> ReadinessReminder? {
        guard let baseID = AppIntentBaseSelection.selectedBaseID(),
              let tracker = loadTracker(baseID: baseID) else {
            return nil
        }

        let dismissalStore = NotificationDismissalStore()
        return ReadinessReminderBuilder.reminders(from: tracker)
            .first { !dismissalStore.isDismissed(baseID: baseID, notificationID: $0.id) }
    }

    nonisolated static func spokenSummary(for reminder: ReadinessReminder) -> String {
        "\(reminder.title). \(reminder.subtitle)"
    }

    nonisolated static func emptySummary() -> String {
        "You don't have any active readiness reminders. Add due dates in Assignment to track them here."
    }

    private static func loadTracker(baseID: String) -> ReadinessTracker? {
        guard let container = ModelContainerFactory.make() else { return nil }
        let context = ModelContext(container)
        let id = baseID
        let descriptor = FetchDescriptor<ReadinessTracker>(
            predicate: #Predicate { $0.baseID == id }
        )
        return try? context.fetch(descriptor).first
    }
}
