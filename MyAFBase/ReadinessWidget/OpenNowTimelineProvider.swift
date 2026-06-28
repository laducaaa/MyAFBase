import WidgetKit

struct OpenNowWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: OpenNowWidgetSnapshot
    let selectedBookmark: OpenNowWidgetItemSnapshot?
}

struct OpenNowTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = OpenNowWidgetEntry
    typealias Intent = OpenNowWidgetIntent

    func placeholder(in context: Context) -> OpenNowWidgetEntry {
        sampleEntry(selectedBookmark: OpenNowWidgetSnapshot.sampleBookmarks.first)
    }

    func snapshot(for configuration: OpenNowWidgetIntent, in context: Context) async -> OpenNowWidgetEntry {
        if context.isPreview {
            return sampleEntry(selectedBookmark: OpenNowWidgetSnapshot.sampleBookmarks.first)
        }
        return entry(for: configuration, family: context.family)
    }

    func timeline(for configuration: OpenNowWidgetIntent, in context: Context) async -> Timeline<OpenNowWidgetEntry> {
        let entry = entry(for: configuration, family: context.family)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func entry(for configuration: OpenNowWidgetIntent, family: WidgetFamily) -> OpenNowWidgetEntry {
        let snapshot = WidgetDataStore.loadOpenNow() ?? .placeholder
        let selectedBookmark = resolvedBookmark(from: configuration, snapshot: snapshot, family: family)
        return OpenNowWidgetEntry(date: .now, snapshot: snapshot, selectedBookmark: selectedBookmark)
    }

    private func resolvedBookmark(
        from configuration: OpenNowWidgetIntent,
        snapshot: OpenNowWidgetSnapshot,
        family: WidgetFamily
    ) -> OpenNowWidgetItemSnapshot? {
        guard family == .systemSmall else { return nil }

        if let bookmarkID = configuration.bookmark?.id,
           let match = snapshot.bookmark(for: bookmarkID) {
            return match
        }

        return snapshot.bookmarks.first
    }

    private func sampleEntry(selectedBookmark: OpenNowWidgetItemSnapshot?) -> OpenNowWidgetEntry {
        OpenNowWidgetEntry(date: .now, snapshot: .sample, selectedBookmark: selectedBookmark)
    }
}

private extension OpenNowWidgetSnapshot {
    static let sampleBookmarks: [OpenNowWidgetItemSnapshot] = [
        OpenNowWidgetItemSnapshot(
            id: "resource-fitness",
            name: "Eglin Fitness Center",
            categoryLabel: "Fitness",
            systemImage: "figure.strengthtraining.traditional",
            detail: "Open 24 hours",
            statusLabel: "Open",
            isOpen: true
        ),
        OpenNowWidgetItemSnapshot(
            id: "resource-dfac",
            name: "Main Dining Facility",
            categoryLabel: "Dining",
            systemImage: "fork.knife",
            detail: "8:00 AM – 6:30 PM",
            statusLabel: "Open",
            isOpen: true
        ),
        OpenNowWidgetItemSnapshot(
            id: "gate-main",
            name: "Main Gate",
            categoryLabel: "Gate",
            systemImage: "door.left.hand.open",
            detail: "Open 24 hours",
            statusLabel: "Open",
            isOpen: true
        )
    ]

    static let sample = OpenNowWidgetSnapshot(
        baseID: "eglin",
        baseName: "Eglin AFB",
        items: sampleBookmarks,
        bookmarks: sampleBookmarks,
        updatedAt: .now
    )

    static let placeholder = OpenNowWidgetSnapshot(
        baseID: "",
        baseName: "MyAFBase",
        items: [],
        bookmarks: [],
        updatedAt: .now
    )
}
