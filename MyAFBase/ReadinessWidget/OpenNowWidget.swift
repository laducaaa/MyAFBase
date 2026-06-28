import SwiftUI
import WidgetKit

struct OpenNowWidget: Widget {
    static let kind = WidgetKinds.openNow

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: OpenNowWidgetIntent.self,
            provider: OpenNowTimelineProvider()
        ) { entry in
            OpenNowWidgetView(entry: entry)
        }
        .configurationDisplayName("Open Now")
        .description("Dining, fitness, medical, and gates open right now.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
