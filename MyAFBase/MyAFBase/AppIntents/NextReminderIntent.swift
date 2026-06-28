import AppIntents
import SwiftUI

struct NextReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Reminder"
    static var description = IntentDescription("Shows your next readiness reminder.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let reminder = await AppIntentReminderResolver.nextActiveReminder() else {
            let spoken = AppIntentReminderResolver.emptySummary()
            return .result(
                dialog: IntentDialog(stringLiteral: spoken),
                view: EmptyReminderSnippetView(message: spoken)
            )
        }

        let spoken = AppIntentReminderResolver.spokenSummary(for: reminder)
        return .result(
            dialog: IntentDialog(stringLiteral: spoken),
            view: NextReminderSnippetView(reminder: reminder)
        )
    }
}
