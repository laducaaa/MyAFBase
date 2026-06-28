import AppIntents
import Foundation

public struct EmergencyContactEntity: AppEntity, Identifiable, Sendable {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Emergency Contact")
    public static var defaultQuery = EmergencyContactEntityQuery()

    public var id: String
    public var title: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    init(contact: EmergencyContactSnapshot) {
        self.id = contact.id
        self.title = contact.label
    }
}

public struct EmergencyContactEntityQuery: EntityQuery, EnumerableEntityQuery {
    public init() {}

    public func allEntities() async throws -> [EmergencyContactEntity] {
        let contacts = WidgetDataStore.loadEmergency()?.contacts ?? []
        return contacts.map(EmergencyContactEntity.init(contact:))
    }

    public func entities(for identifiers: [EmergencyContactEntity.ID]) async throws -> [EmergencyContactEntity] {
        let contacts = WidgetDataStore.loadEmergency()?.contacts ?? []
        return identifiers.compactMap { id in
            contacts.first(where: { $0.id == id }).map(EmergencyContactEntity.init(contact:))
        }
    }

    public func suggestedEntities() async throws -> [EmergencyContactEntity] {
        try await allEntities()
    }

    public func defaultResult() async -> EmergencyContactEntity? {
        (try? await allEntities())?.first
    }
}

public struct EmergencyWidgetIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Emergency Contacts"
    public static var description = IntentDescription("Pick which emergency number appears on the small widget.")

    @Parameter(title: "Contact")
    public var contact: EmergencyContactEntity?

    public init() {}

    public init(contact: EmergencyContactEntity?) {
        self.contact = contact
    }
}
