import AppIntents
import SwiftUI

struct SwitchBaseIntent: AppIntent {
    static var title: LocalizedStringResource = "Switch Base"
    static var description = IntentDescription("Changes your active installation.")
    static var openAppWhenRun = true

    @Parameter(title: "Base")
    var base: BaseEntity

    init() {
        self.base = BaseEntity(id: "", name: "", location: "")
    }

    init(base: BaseEntity) {
        self.base = base
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard !base.id.isEmpty else {
            throw $base.needsValueError("Which base would you like to switch to?")
        }

        AppIntentBaseSelection.setSelectedBaseID(base.id)
        await NotificationCenter.default.post(
            name: AppIntentNotifications.didSwitchBase,
            object: nil,
            userInfo: [AppIntentNotifications.baseIDKey: base.id]
        )

        let spoken = "Switched to \(base.name)."
        return .result(
            dialog: IntentDialog(stringLiteral: spoken),
            view: SwitchBaseSnippetView(baseName: base.name, location: base.location)
        )
    }
}
