import Foundation

struct EmergencyContactSnapshot: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let label: String
    let number: String
    let systemImage: String
    let isUniversalEmergency: Bool
}

struct EmergencyWidgetSnapshot: Codable, Equatable, Sendable {
    var baseID: String
    var baseName: String
    var contacts: [EmergencyContactSnapshot]
    var updatedAt: Date

    var primaryContacts: [EmergencyContactSnapshot] {
        contacts
    }

    func contact(id: String) -> EmergencyContactSnapshot? {
        contacts.first { $0.id == id }
    }
}
