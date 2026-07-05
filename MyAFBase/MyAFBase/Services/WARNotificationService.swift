import Foundation
import UserNotifications

/// Local notifications for the WAR Tracker: a daily "log something" nudge,
/// a weekly "WAR due Friday" reminder, and award-deadline countdowns.
/// Mirrors `ReadinessNotificationService`'s identifier-prefix scheme.
enum WARNotificationService {
    private static let dailyIdentifier = "war.daily"
    private static let weeklyIdentifier = "war.weekly"
    private static let deadlineIdentifierPrefix = "war.deadline"
    private static let deadlineReminderOffsets = [7, 3, 1]
    private static let deadlineNotificationHour = 9

    // MARK: - Daily nudge

    @MainActor
    static func setDailyNudgeEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            guard await requestAuthorization() else {
                WARSettingsStore.dailyNudgeEnabled = false
                return false
            }
        }
        WARSettingsStore.dailyNudgeEnabled = enabled
        await rescheduleDailyNudge()
        return enabled
    }

    @MainActor
    static func rescheduleDailyNudge() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])
        guard WARSettingsStore.dailyNudgeEnabled, await hasAuthorization(center: center) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Log something today?"
        content.body = "Add a quick WAR Tracker entry before you forget what you worked on."
        content.sound = .default

        var components = DateComponents()
        components.hour = WARSettingsStore.dailyNudgeHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Weekly reminder

    @MainActor
    static func setWeeklyReminderEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            guard await requestAuthorization() else {
                WARSettingsStore.weeklyReminderEnabled = false
                return false
            }
        }
        WARSettingsStore.weeklyReminderEnabled = enabled
        await rescheduleWeeklyReminder()
        return enabled
    }

    @MainActor
    static func rescheduleWeeklyReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklyIdentifier])
        guard WARSettingsStore.weeklyReminderEnabled, await hasAuthorization(center: center) else { return }

        let content = UNMutableNotificationContent()
        content.title = "WAR due Friday"
        content.body = "Wrap up this week's accomplishments in WAR Tracker."
        content.sound = .default

        var components = DateComponents()
        components.weekday = WARSettingsStore.weeklyReminderWeekday
        components.hour = WARSettingsStore.weeklyReminderHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: weeklyIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Award deadlines

    @MainActor
    static func rescheduleDeadlineReminders(
        _ deadlines: [WARAwardDeadline],
        baseNameProvider: (String) -> String
    ) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let existingIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix(deadlineIdentifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: existingIdentifiers)

        guard await hasAuthorization(center: center) else { return }

        for deadline in deadlines {
            await scheduleDeadlineReminders(deadline: deadline, baseName: baseNameProvider(deadline.baseID), center: center)
        }
    }

    @MainActor
    private static func scheduleDeadlineReminders(
        deadline: WARAwardDeadline,
        baseName: String,
        center: UNUserNotificationCenter
    ) async {
        let calendar = Calendar.current
        let startOfDue = calendar.startOfDay(for: deadline.dueDate)

        for offset in deadlineReminderOffsets {
            guard let reminderDay = calendar.date(byAdding: .day, value: -offset, to: startOfDue),
                  let fireDate = calendar.date(
                    bySettingHour: deadlineNotificationHour,
                    minute: 0,
                    second: 0,
                    of: reminderDay
                  ),
                  fireDate > Date() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = deadline.title
            content.body = offset == 1
                ? "Due tomorrow — \(baseName)."
                : "Due in \(offset) days — \(baseName)."
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(deadlineIdentifierPrefix).\(deadline.id.uuidString).\(offset)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    // MARK: - Shared

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
    private static func hasAuthorization(center: UNUserNotificationCenter) async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral
    }

    @MainActor
    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending.map(\.identifier).filter { $0.hasPrefix("war.") }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
