import Foundation

extension Base {
    var dataUpdatedDate: Date? {
        guard let dataUpdatedAt else { return nil }
        return ISO8601DateFormatter().date(from: dataUpdatedAt)
    }

    var formattedDataUpdated: String? {
        guard let dataUpdatedDate else { return nil }
        return dataUpdatedDate.formatted(date: .abbreviated, time: .omitted)
    }
}
