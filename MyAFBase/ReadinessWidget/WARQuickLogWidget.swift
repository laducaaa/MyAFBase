import SwiftUI
import WidgetKit

struct WARQuickLogWidget: Widget {
    static let kind = WidgetKinds.warQuickLog

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WARQuickLogTimelineProvider()) { entry in
            WARQuickLogWidgetView(entry: entry)
        }
        .configurationDisplayName("WAR Tracker")
        .description("This week's logged accomplishments, with one tap to add another.")
        .supportedFamilies([.systemSmall])
    }
}
