import Foundation

nonisolated struct WARWidgetSnapshot: Codable, Equatable, Sendable {
    var baseID: String
    var entriesThisWeek: Int
    var weekRangeLabel: String
    var updatedAt: Date

    static let placeholder = WARWidgetSnapshot(
        baseID: "",
        entriesThisWeek: 0,
        weekRangeLabel: "",
        updatedAt: .distantPast
    )
}
