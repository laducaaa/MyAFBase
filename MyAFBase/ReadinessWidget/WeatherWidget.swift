import SwiftUI
import WidgetKit

struct WeatherWidget: Widget {
    static let kind = WidgetKinds.weather

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("Base Weather")
        .description("Current conditions at your selected base.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
