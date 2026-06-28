import AppIntents

struct MyAFBaseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextPayDateIntent(),
            phrases: [
                "When's my next pay in \(.applicationName)",
                "Next pay date in \(.applicationName)",
                "When do I get paid in \(.applicationName)"
            ],
            shortTitle: "Next Pay",
            systemImageName: "dollarsign.circle"
        )

        AppShortcut(
            intent: NextReminderIntent(),
            phrases: [
                "What's my next reminder in \(.applicationName)",
                "What readiness item is due next in \(.applicationName)",
                "Next reminder in \(.applicationName)"
            ],
            shortTitle: "Next Reminder",
            systemImageName: "calendar.badge.clock"
        )

        AppShortcut(
            intent: SwitchBaseIntent(),
            phrases: [
                "Switch base to \(\.$base) in \(.applicationName)",
                "Change base to \(\.$base) in \(.applicationName)",
                "Set my base to \(\.$base) in \(.applicationName)"
            ],
            shortTitle: "Switch Base",
            systemImageName: "building.2"
        )
    }
}
