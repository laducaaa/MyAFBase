import WidgetKit

struct PayWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: PayWidgetSnapshot
}

struct PayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PayWidgetEntry {
        PayWidgetEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (PayWidgetEntry) -> Void) {
        completion(entry(for: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PayWidgetEntry>) -> Void) {
        let entry = entry(for: context)
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
        let sixHours = calendar.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21_600)
        let refresh = min(startOfTomorrow, sixHours)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func entry(for context: Context) -> PayWidgetEntry {
        if context.isPreview {
            return PayWidgetEntry(date: .now, snapshot: .sample)
        }

        let snapshot = WidgetDataStore.loadPay() ?? .placeholder
        return PayWidgetEntry(date: .now, snapshot: snapshot)
    }
}

private extension PayWidgetSnapshot {
    static let sample = PayWidgetSnapshot(
        nextTitle: "Mid-month pay",
        nextDate: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now,
        daysUntil: 5,
        isSpecial: false,
        symbolName: "dollarsign.circle.fill",
        upcoming: [
            PayWidgetUpcomingItem(
                title: "Mid-month pay",
                date: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now,
                daysUntil: 5,
                isSpecial: false,
                symbolName: "dollarsign.circle.fill"
            ),
            PayWidgetUpcomingItem(
                title: "Month-end pay",
                date: Calendar.current.date(byAdding: .day, value: 19, to: .now) ?? .now,
                daysUntil: 19,
                isSpecial: false,
                symbolName: "banknote.fill"
            )
        ],
        updatedAt: .now
    )

    static let placeholder = PayWidgetSnapshot(
        nextTitle: "",
        nextDate: .now,
        daysUntil: 0,
        isSpecial: false,
        symbolName: "dollarsign.circle",
        upcoming: [],
        updatedAt: .now
    )
}
