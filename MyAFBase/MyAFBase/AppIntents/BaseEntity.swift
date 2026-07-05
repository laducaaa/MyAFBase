import AppIntents
import Foundation

public struct BaseEntity: AppEntity, Identifiable, Sendable {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Air Force Base")
    public static var defaultQuery = BaseEntityQuery()

    public var id: String
    public var name: String
    public var location: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(location)"
        )
    }

    public init(id: String, name: String, location: String) {
        self.id = id
        self.name = name
        self.location = location
    }

    init(entry: BaseIndexEntry) {
        self.id = entry.id
        self.name = entry.name
        self.location = entry.location
    }
}

public struct BaseEntityQuery: EntityQuery, EnumerableEntityQuery {
    public init() {}

    public func allEntities() async throws -> [BaseEntity] {
        let entries = await LocalJSONDataService.shared.loadPickerBaseIndex()
        return entries.map(BaseEntity.init(entry:))
    }

    public func entities(for identifiers: [BaseEntity.ID]) async throws -> [BaseEntity] {
        let all = try await allEntities()
        return identifiers.compactMap { id in
            all.first { $0.id == id }
        }
    }

    public func suggestedEntities() async throws -> [BaseEntity] {
        try await allEntities()
    }

    public func defaultResult() async -> BaseEntity? {
        guard let selectedID = AppIntentBaseSelection.selectedBaseID() else {
            return try? await allEntities().first
        }
        return try? await entities(for: [selectedID]).first
    }
}
