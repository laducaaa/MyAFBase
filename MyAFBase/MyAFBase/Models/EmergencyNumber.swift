import Foundation

struct EmergencyNumber: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    let number: String
}
