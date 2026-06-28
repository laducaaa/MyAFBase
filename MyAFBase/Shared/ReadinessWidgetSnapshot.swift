import Foundation

struct ReadinessWidgetItemSnapshot: Codable, Equatable, Sendable, Identifiable {
    let kind: String
    let title: String
    let systemImage: String
    let countdownValue: Int?
    let countdownLabel: String
    let detailLabel: String
    let statusRaw: String

    var id: String { kind }

    var itemKind: ReadinessItemKind? {
        ReadinessItemKind(rawValue: kind)
    }
}

struct ReadinessWidgetSnapshot: Codable, Equatable, Sendable {
    var activeBaseID: String
    var activeBaseName: String
    var items: [ReadinessWidgetItemSnapshot]
    var updatedAt: Date

    func item(for kind: ReadinessItemKind) -> ReadinessWidgetItemSnapshot? {
        items.first { $0.kind == kind.rawValue }
    }

    func items(for kinds: [ReadinessItemKind]) -> [ReadinessWidgetItemSnapshot] {
        kinds.compactMap { item(for: $0) }
    }
}
