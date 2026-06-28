import Foundation
import SwiftData

struct ResolvedSavedItem: Identifiable, Equatable {
    let bookmark: Bookmark
    let gate: Gate?
    let resource: Resource?
    let event: Event?

    var id: String { "\(bookmark.itemType)-\(bookmark.itemID)" }
    var savedAt: Date { bookmark.createdAt }

    static func == (lhs: ResolvedSavedItem, rhs: ResolvedSavedItem) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
final class BookmarkStore {
    private let modelContext: ModelContext
    private(set) var changeToken = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func allBookmarks() -> [Bookmark] {
        let descriptor = FetchDescriptor<Bookmark>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func isBookmarked(baseID: String, itemID: String, itemType: BookmarkItemType) -> Bool {
        bookmarkSnapshot().contains {
            $0.baseID == baseID && $0.itemID == itemID && $0.itemType == itemType.rawValue
        }
    }

    func toggleGate(baseID: String, gateID: String) {
        toggle(baseID: baseID, itemID: gateID, itemType: .gate)
    }

    func toggleResource(baseID: String, resourceID: String) {
        toggle(baseID: baseID, itemID: resourceID, itemType: .resource)
    }

    func toggleEvent(baseID: String, eventID: String) {
        toggle(baseID: baseID, itemID: eventID, itemType: .event)
    }

    func bookmarkedGates(for base: Base) -> [Gate] {
        let bookmarkedIDs = Set(
            bookmarkSnapshot()
                .filter { $0.baseID == base.id && $0.itemType == BookmarkItemType.gate.rawValue }
                .map(\.itemID)
        )
        return base.gates.filter { bookmarkedIDs.contains($0.id) }
    }

    func bookmarkedResources(for base: Base) -> [Resource] {
        let bookmarkedIDs = Set(
            bookmarkSnapshot()
                .filter { $0.baseID == base.id && $0.itemType == BookmarkItemType.resource.rawValue }
                .map(\.itemID)
        )
        return base.resources.filter { bookmarkedIDs.contains($0.id) }
    }

    func bookmarkedEvents(for base: Base) -> [Event] {
        let bookmarkedIDs = Set(
            bookmarkSnapshot()
                .filter { $0.baseID == base.id && $0.itemType == BookmarkItemType.event.rawValue }
                .map(\.itemID)
        )
        return base.events.filter { bookmarkedIDs.contains($0.id) }
    }

    func savedCount(for base: Base, category: HomeSavedCategory = .all) -> Int {
        bookmarks(for: base, category: category).count
    }

    func resolvedSavedItems(
        for base: Base,
        category: HomeSavedCategory,
        limit: Int? = nil
    ) -> [ResolvedSavedItem] {
        var bookmarks = bookmarks(for: base, category: category)

        if let limit {
            bookmarks = Array(bookmarks.prefix(limit))
        }

        return bookmarks.compactMap { resolve(bookmark: $0, base: base) }
    }

    func clearAllBookmarks() {
        for bookmark in allBookmarks() {
            modelContext.delete(bookmark)
        }
        try? modelContext.save()
        notifyBookmarksChanged()
    }

    private func toggle(baseID: String, itemID: String, itemType: BookmarkItemType) {
        if let existing = allBookmarks().first(where: {
            $0.baseID == baseID && $0.itemID == itemID && $0.itemType == itemType.rawValue
        }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(Bookmark(baseID: baseID, itemID: itemID, itemType: itemType.rawValue))
        }
        try? modelContext.save()
        notifyBookmarksChanged()
    }

    private func bookmarkSnapshot() -> [Bookmark] {
        _ = changeToken
        return allBookmarks()
    }

    private func notifyBookmarksChanged() {
        changeToken += 1
    }

    private func bookmarks(for base: Base, category: HomeSavedCategory) -> [Bookmark] {
        bookmarkSnapshot()
            .filter { bookmark in
                guard bookmark.baseID == base.id else { return false }
                guard let itemType = category.bookmarkItemType else { return true }
                return bookmark.itemType == itemType.rawValue
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func resolve(bookmark: Bookmark, base: Base) -> ResolvedSavedItem? {
        switch BookmarkItemType(rawValue: bookmark.itemType) {
        case .gate:
            guard let gate = base.gates.first(where: { $0.id == bookmark.itemID }) else { return nil }
            return ResolvedSavedItem(bookmark: bookmark, gate: gate, resource: nil, event: nil)
        case .resource:
            guard let resource = base.resources.first(where: { $0.id == bookmark.itemID }) else { return nil }
            return ResolvedSavedItem(bookmark: bookmark, gate: nil, resource: resource, event: nil)
        case .event:
            guard let event = base.events.first(where: { $0.id == bookmark.itemID }) else { return nil }
            return ResolvedSavedItem(bookmark: bookmark, gate: nil, resource: nil, event: event)
        case .none:
            return nil
        }
    }
}
