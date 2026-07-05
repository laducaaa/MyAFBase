import AppIntents

/// Opens WAR Tracker's quick-add sheet, optionally prefilled with dictated
/// text. Lives in `Shared` so both the app (Siri shortcut registration) and
/// the widget extension (interactive "Log" button) can use it — tapping or
/// invoking it always foregrounds the app since the actual save happens
/// through the on-device SwiftData store there.
struct LogAccomplishmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Accomplishment"
    static var description = IntentDescription("Opens WAR Tracker to log something you did today.")
    static var openAppWhenRun = true

    @Parameter(title: "What did you do?", default: "")
    var accomplishment: String

    init() {
        self.accomplishment = ""
    }

    init(accomplishment: String) {
        self.accomplishment = accomplishment
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = accomplishment.trimmingCharacters(in: .whitespacesAndNewlines)
        AppIntentBaseSelection.setPendingWARQuickLog(text: text)
        await NotificationCenter.default.post(
            name: AppIntentNotifications.didRequestWARQuickLog,
            object: nil,
            userInfo: [AppIntentNotifications.warQuickLogTextKey: text]
        )

        let spoken = text.isEmpty
            ? "Opening WAR Tracker."
            : "Got it. Opening WAR Tracker to review your entry."
        return .result(dialog: IntentDialog(stringLiteral: spoken))
    }
}
