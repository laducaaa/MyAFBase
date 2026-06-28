import Foundation
import UserNotifications

enum ReadinessNotificationService {
    static let remindersEnabledKey = "readinessRemindersEnabled"

    static var remindersEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: remindersEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: remindersEnabledKey) }
    }

    private static let reminderOffsets = [14, 7, 1]
    private static let notificationHour = 9

    @MainActor
    static func setRemindersEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            let granted = await requestAuthorization()
            guard granted else {
                remindersEnabled = false
                return false
            }
        } else {
            await cancelAll()
        }

        remindersEnabled = enabled
        return enabled
    }

    @MainActor
    static func reschedule(for tracker: ReadinessTracker, baseName: String) async {
        await cancel(for: tracker.baseID)

        guard remindersEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        for item in ReadinessReminderItem.standardItems {
            if let dueDate = item.date(tracker) {
                await scheduleDueDateReminders(
                    baseID: tracker.baseID,
                    itemID: item.id,
                    title: item.title,
                    dueDate: dueDate,
                    baseName: baseName,
                    center: center
                )
            }
        }

        if let start = tracker.pcsWindowStart {
            await scheduleDueDateReminders(
                baseID: tracker.baseID,
                itemID: "pcs-window-start",
                title: "PCS window opens",
                dueDate: start,
                baseName: baseName,
                center: center
            )
        }

        if let end = tracker.pcsWindowEnd {
            await scheduleDueDateReminders(
                baseID: tracker.baseID,
                itemID: "pcs-window-end",
                title: "PCS window closes",
                dueDate: end,
                baseName: baseName,
                center: center
            )
        }
    }

    @MainActor
    static func rescheduleAll(_ trackers: [ReadinessTracker], baseNameProvider: (String) -> String) async {
        guard remindersEnabled else {
            await cancelAll()
            return
        }

        await cancelAll()
        for tracker in trackers {
            await reschedule(for: tracker, baseName: baseNameProvider(tracker.baseID))
        }
    }

    @MainActor
    private static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    @MainActor
    private static func scheduleDueDateReminders(
        baseID: String,
        itemID: String,
        title: String,
        dueDate: Date,
        baseName: String,
        center: UNUserNotificationCenter
    ) async {
        let calendar = Calendar.current
        let startOfDue = calendar.startOfDay(for: dueDate)

        for offset in reminderOffsets {
            guard let reminderDay = calendar.date(byAdding: .day, value: -offset, to: startOfDue),
                  let fireDate = calendar.date(
                    bySettingHour: notificationHour,
                    minute: 0,
                    second: 0,
                    of: reminderDay
                  ),
                  fireDate > Date() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = offset == 1
                ? "Due tomorrow while assigned to \(baseName)."
                : "Due in \(offset) days while assigned to \(baseName)."
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "readiness.\(baseID).\(itemID).\(offset)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }

        if let dueFireDate = calendar.date(
            bySettingHour: notificationHour,
            minute: 0,
            second: 0,
            of: startOfDue
        ), dueFireDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = "Due today while assigned to \(baseName)."
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueFireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "readiness.\(baseID).\(itemID).due"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    @MainActor
    static func cancel(for baseID: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("readiness.\(baseID).") }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    @MainActor
    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("readiness.") }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

private struct ReadinessReminderItem {
    let id: String
    let title: String
    let date: (ReadinessTracker) -> Date?

    static let standardItems: [ReadinessReminderItem] = [
        ReadinessReminderItem(id: "fitness", title: "Fitness test due", date: { $0.fitnessTestDue }),
        ReadinessReminderItem(id: "dental", title: "Annual dental due", date: { $0.dentalDue }),
        ReadinessReminderItem(id: "eval", title: "EPR / OPB closeout", date: { $0.evalCloseoutDue }),
        ReadinessReminderItem(id: "cac", title: "CAC expiration", date: { $0.cacExpiration }),
        ReadinessReminderItem(id: "clearance", title: "Clearance renewal", date: { $0.clearanceRenewal })
    ]
}
