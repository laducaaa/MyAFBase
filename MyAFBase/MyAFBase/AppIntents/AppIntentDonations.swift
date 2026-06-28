import AppIntents
import Foundation

enum AppIntentDonations {
    static func recordGateViewed(gateName: String, baseID: String, baseName: String, location: String = "") {
        donate(
            ViewGateIntent(
                gateName: gateName,
                base: BaseEntity(id: baseID, name: baseName, location: location)
            )
        )
    }

    static func recordResourceBookmarked(resourceName: String, baseID: String, baseName: String, location: String = "") {
        donate(
            BookmarkResourceIntent(
                resourceName: resourceName,
                base: BaseEntity(id: baseID, name: baseName, location: location)
            )
        )
    }

    static func recordReadinessChecked(baseID: String, baseName: String, location: String = "") {
        donate(
            ViewReadinessIntent(
                base: BaseEntity(id: baseID, name: baseName, location: location)
            )
        )
    }

    private static func donate<I: AppIntent>(_ intent: I) {
        Task {
            try? await intent.donate()
        }
    }
}
