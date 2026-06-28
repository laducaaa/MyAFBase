import Foundation

struct Event: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let date: Date
    let endDate: Date?
    let location: String
    let address: String?
    let description: String
    let category: EventCategory?

    var displayAddress: String? {
        if let address, !address.isEmpty { return address }
        if !location.isEmpty { return location }
        return nil
    }

    var timeRangeText: String? {
        let formatter = Date.FormatStyle(date: .omitted, time: .shortened)
        if let endDate {
            return "\(date.formatted(formatter)) – \(endDate.formatted(formatter))"
        }
        return date.formatted(formatter)
    }
}
