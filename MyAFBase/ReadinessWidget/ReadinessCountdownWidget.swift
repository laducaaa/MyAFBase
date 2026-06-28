import SwiftUI
import WidgetKit

struct ReadinessCountdownWidget: Widget {
    let kind = "ReadinessCountdownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ReadinessCountdownWidgetIntent.self,
            provider: ReadinessTimelineProvider()
        ) { entry in
            ReadinessCountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Readiness Countdown")
        .description("Days until your next PT test, dental, EPR, and other due dates.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
