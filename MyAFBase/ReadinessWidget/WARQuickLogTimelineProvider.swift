import WidgetKit

struct WARQuickLogEntry: TimelineEntry {
    let date: Date
    let snapshot: WARWidgetSnapshot
}

struct WARQuickLogTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WARQuickLogEntry {
        WARQuickLogEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (WARQuickLogEntry) -> Void) {
        completion(entry(for: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WARQuickLogEntry>) -> Void) {
        let entry = entry(for: context)
        let calendar = Calendar.current
        let sixHours = calendar.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21_600)
        completion(Timeline(entries: [entry], policy: .after(sixHours)))
    }

    private func entry(for context: Context) -> WARQuickLogEntry {
        if context.isPreview {
            return WARQuickLogEntry(date: .now, snapshot: .sample)
        }
        let snapshot = WidgetDataStore.loadWARTracker() ?? .placeholder
        return WARQuickLogEntry(date: .now, snapshot: snapshot)
    }
}

private extension WARWidgetSnapshot {
    static let sample = WARWidgetSnapshot(
        baseID: "sample",
        entriesThisWeek: 3,
        weekRangeLabel: "Jun 2 – Jun 8",
        updatedAt: .now
    )
}
