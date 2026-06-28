import WidgetKit

struct WeatherWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WeatherWidgetSnapshot
}

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherWidgetEntry {
        WeatherWidgetEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherWidgetEntry) -> Void) {
        completion(entry(for: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherWidgetEntry>) -> Void) {
        let entry = entry(for: context)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func entry(for context: Context) -> WeatherWidgetEntry {
        if context.isPreview {
            return WeatherWidgetEntry(date: .now, snapshot: .sample)
        }

        let snapshot = WidgetDataStore.loadWeather() ?? .placeholder
        return WeatherWidgetEntry(date: .now, snapshot: snapshot)
    }
}

private extension WeatherWidgetSnapshot {
    static let sample = WeatherWidgetSnapshot(
        baseID: "eglin",
        baseName: "Eglin AFB",
        location: "Fort Walton Beach, FL",
        tempF: 78,
        feelsLikeF: 81,
        conditionName: "Partly Cloudy",
        symbolName: "cloud.sun.fill",
        windMph: 12,
        humidity: 58,
        isAvailable: true,
        updatedAt: .now
    )

    static let placeholder = WeatherWidgetSnapshot(
        baseID: "",
        baseName: "MyAFBase",
        location: nil,
        tempF: nil,
        feelsLikeF: nil,
        conditionName: "Open app to load",
        symbolName: "cloud.fill",
        windMph: nil,
        humidity: nil,
        isAvailable: false,
        updatedAt: .now
    )
}
