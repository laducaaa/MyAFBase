import Foundation

struct Resource: Codable, Identifiable, Equatable {
    let id: String
    let slug: String?
    let name: String
    let category: ResourceCategory
    let description: String?
    let hours: String?
    let address: String?
    let phone: String?
    let url: String?
    let building: String?
    let type: ResourceType?
    let value: String?

    var displayHours: String? {
        if let hours, !hours.isEmpty { return hours }
        if type == .hours, let value, !value.isEmpty { return value }
        return nil
    }

    var displayAddress: String? {
        if let address, !address.isEmpty { return address }
        if let building, !building.isEmpty { return building }
        if type == .location, let value, !value.isEmpty { return value }
        return nil
    }

    var displayPhone: String? {
        if let phone, !phone.isEmpty { return phone }
        if type == .phone, let value, !value.isEmpty { return value }
        return nil
    }

    var displayURL: String? {
        if let url, !url.isEmpty { return url }
        if type == .url, let value, !value.isEmpty { return value }
        return nil
    }
}
