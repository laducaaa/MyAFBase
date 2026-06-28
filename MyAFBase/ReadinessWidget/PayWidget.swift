import SwiftUI
import WidgetKit

struct PayWidget: Widget {
    static let kind = WidgetKinds.payCalendar

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PayTimelineProvider()) { entry in
            PayWidgetView(entry: entry)
        }
        .configurationDisplayName("Pay Calendar")
        .description("Countdown to your next military pay date.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
