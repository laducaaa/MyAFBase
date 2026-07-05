import Foundation

/// App-wide WAR Tracker settings. Backed by `UserDefaults` like
/// `ReadinessNotificationService` — a single lightweight settings surface
/// doesn't need its own SwiftData row.
enum WARSettingsStore {
    private static let memberTypeKey = "warTrackerMemberType"
    private static let dailyNudgeEnabledKey = "warTrackerDailyNudgeEnabled"
    private static let dailyNudgeHourKey = "warTrackerDailyNudgeHour"
    private static let weeklyReminderEnabledKey = "warTrackerWeeklyReminderEnabled"
    private static let weeklyReminderWeekdayKey = "warTrackerWeeklyReminderWeekday"
    private static let weeklyReminderHourKey = "warTrackerWeeklyReminderHour"
    private static let lockEnabledKey = "warTrackerLockEnabled"
    private static let autoDeleteEnabledKey = "warTrackerAutoDeleteEnabled"
    private static let autoDeleteAfterYearsKey = "warTrackerAutoDeleteAfterYears"

    static var memberType: WARMemberType {
        get {
            UserDefaults.standard.string(forKey: memberTypeKey)
                .flatMap(WARMemberType.init(rawValue:)) ?? .enlisted
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: memberTypeKey) }
    }

    static var dailyNudgeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: dailyNudgeEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: dailyNudgeEnabledKey) }
    }

    /// Hour of day (0-23) the daily nudge fires. Defaults to 8 PM.
    static var dailyNudgeHour: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: dailyNudgeHourKey) as? Int
            return stored ?? 20
        }
        set { UserDefaults.standard.set(newValue, forKey: dailyNudgeHourKey) }
    }

    static var weeklyReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: weeklyReminderEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: weeklyReminderEnabledKey) }
    }

    /// `Calendar` weekday component (1 = Sunday ... 6 = Friday). Defaults to Friday.
    static var weeklyReminderWeekday: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: weeklyReminderWeekdayKey) as? Int
            return stored ?? 6
        }
        set { UserDefaults.standard.set(newValue, forKey: weeklyReminderWeekdayKey) }
    }

    static var weeklyReminderHour: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: weeklyReminderHourKey) as? Int
            return stored ?? 15
        }
        set { UserDefaults.standard.set(newValue, forKey: weeklyReminderHourKey) }
    }

    /// Face ID / passcode gate on the WAR Tracker section. Off by default.
    static var lockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: lockEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: lockEnabledKey) }
    }

    /// Off by default — entries are kept forever unless the user opts in.
    static var autoDeleteEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoDeleteEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoDeleteEnabledKey) }
    }

    /// Only meaningful when `autoDeleteEnabled` is true.
    static var autoDeleteAfterYears: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: autoDeleteAfterYearsKey) as? Int
            return stored ?? 3
        }
        set { UserDefaults.standard.set(newValue, forKey: autoDeleteAfterYearsKey) }
    }
}
