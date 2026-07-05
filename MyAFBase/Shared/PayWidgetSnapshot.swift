import Foundation

nonisolated struct PayWidgetUpcomingItem: Codable, Equatable, Sendable {
    var title: String
    var date: Date
    var daysUntil: Int
    var isSpecial: Bool
    var symbolName: String

    var daysLabel: String {
        switch daysUntil {
        case 0: "Today"
        case 1: "1 day"
        default: "\(daysUntil) days"
        }
    }

    var shortDateLabel: String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}

nonisolated struct PayWidgetSnapshot: Codable, Equatable, Sendable {
    var nextTitle: String
    var nextDate: Date
    var daysUntil: Int
    var isSpecial: Bool
    var symbolName: String
    var upcoming: [PayWidgetUpcomingItem]
    var updatedAt: Date

    var isAvailable: Bool {
        !nextTitle.isEmpty
    }

    var daysLabel: String {
        switch daysUntil {
        case 0: "Today"
        case 1: "Tomorrow"
        default: "In \(daysUntil) days"
        }
    }

    var nextDateLabel: String {
        nextDate.formatted(date: .abbreviated, time: .omitted)
    }
}
