import Foundation

struct Gate: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let status: GateStatus
    let hours: String
    let notes: String?
    let traffic: TrafficLevel
    let address: String?
    let latitude: Double?
    let longitude: Double?

    var displayAddress: String? {
        if let address, !address.isEmpty { return address }
        return nil
    }
}
