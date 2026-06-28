import SwiftUI
import WidgetKit

struct EmergencyWidget: Widget {
    static let kind = WidgetKinds.emergency

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: EmergencyWidgetIntent.self,
            provider: EmergencyTimelineProvider()
        ) { entry in
            EmergencyWidgetView(entry: entry)
        }
        .configurationDisplayName("Emergency Contacts")
        .description("One-tap calling for base security, hospital, and 911.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
