import AppIntents
import Foundation

public struct ReadinessItemEntity: AppEntity, Identifiable, Sendable {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Readiness Item")
    public static var defaultQuery = ReadinessItemEntityQuery()

    public var id: String
    public var title: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    init(kind: ReadinessItemKind) {
        self.id = kind.rawValue
        self.title = kind.title
    }
}

public struct ReadinessItemEntityQuery: EntityQuery, EnumerableEntityQuery {
    public init() {}

    public func allEntities() async throws -> [ReadinessItemEntity] {
        ReadinessItemKind.widgetKinds.map(ReadinessItemEntity.init(kind:))
    }

    public func entities(for identifiers: [ReadinessItemEntity.ID]) async throws -> [ReadinessItemEntity] {
        identifiers.compactMap { id in
            guard let kind = ReadinessItemKind(rawValue: id),
                  ReadinessItemKind.widgetKinds.contains(kind) else {
                return nil
            }
            return ReadinessItemEntity(kind: kind)
        }
    }

    public func suggestedEntities() async throws -> [ReadinessItemEntity] {
        try await allEntities()
    }

    public func defaultResult() async -> ReadinessItemEntity? {
        ReadinessItemEntity(kind: .fitness)
    }
}

public struct ReadinessCountdownWidgetIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Readiness Countdown"
    public static var description = IntentDescription("Pick which readiness dates appear on this widget.")

    @Parameter(
        title: "Items",
        default: [],
        size: [.systemSmall: 1, .systemMedium: 3, .systemLarge: 6]
    )
    public var items: [ReadinessItemEntity]

    public init() {
        self.items = []
    }

    public init(items: [ReadinessItemEntity]) {
        self.items = items
    }
}
