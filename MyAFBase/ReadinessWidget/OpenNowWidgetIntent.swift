import AppIntents
import Foundation

public struct OpenNowBookmarkEntity: AppEntity, Identifiable, Sendable {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Bookmark")
    public static var defaultQuery = OpenNowBookmarkEntityQuery()

    public var id: String
    public var title: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    init(item: OpenNowWidgetItemSnapshot) {
        self.id = item.id
        self.title = item.name
    }
}

public struct OpenNowBookmarkEntityQuery: EntityQuery, EnumerableEntityQuery {
    public init() {}

    public func allEntities() async throws -> [OpenNowBookmarkEntity] {
        let bookmarks = WidgetDataStore.loadOpenNow()?.bookmarks ?? []
        return bookmarks.map(OpenNowBookmarkEntity.init(item:))
    }

    public func entities(for identifiers: [OpenNowBookmarkEntity.ID]) async throws -> [OpenNowBookmarkEntity] {
        let bookmarks = WidgetDataStore.loadOpenNow()?.bookmarks ?? []
        return identifiers.compactMap { id in
            bookmarks.first(where: { $0.id == id }).map(OpenNowBookmarkEntity.init(item:))
        }
    }

    public func suggestedEntities() async throws -> [OpenNowBookmarkEntity] {
        try await allEntities()
    }

    public func defaultResult() async -> OpenNowBookmarkEntity? {
        (try? await allEntities())?.first
    }
}

public struct OpenNowWidgetIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Open Now"
    public static var description = IntentDescription("Pick a saved bookmark for the small widget.")

    @Parameter(title: "Bookmark")
    public var bookmark: OpenNowBookmarkEntity?

    public init() {}

    public init(bookmark: OpenNowBookmarkEntity?) {
        self.bookmark = bookmark
    }
}
