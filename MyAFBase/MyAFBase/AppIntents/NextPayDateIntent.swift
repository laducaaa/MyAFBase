import AppIntents
import SwiftUI

struct NextPayDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Pay Date"
    static var description = IntentDescription("Shows your next military pay date.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let snapshot = await AppIntentPayResolver.snapshot()
        let spoken = AppIntentPayResolver.spokenSummary(from: snapshot)

        return .result(
            dialog: IntentDialog(stringLiteral: spoken),
            view: NextPaySnippetView(snapshot: snapshot)
        )
    }
}
