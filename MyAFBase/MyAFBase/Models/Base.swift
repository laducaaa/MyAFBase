import Foundation

struct Base: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let fullName: String
    let location: String
    let description: String
    let wing: String
    let latitude: Double
    let longitude: Double
    let dataUpdatedAt: String?
    let currentNotifications: [NotificationItem]
    let emergencyNumbers: [EmergencyNumber]
    let gates: [Gate]
    let resources: [Resource]
    let events: [Event]
    let newcomers: NewcomersInfo
}
