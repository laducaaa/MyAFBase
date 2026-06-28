import Foundation

struct EmergencyNumber: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let number: String
}
