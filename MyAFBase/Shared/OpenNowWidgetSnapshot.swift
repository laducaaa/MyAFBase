import Foundation

struct OpenNowWidgetItemSnapshot: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let categoryLabel: String
    let systemImage: String
    let detail: String?
    let statusLabel: String
    let isOpen: Bool

    init(
        id: String,
        name: String,
        categoryLabel: String,
        systemImage: String,
        detail: String?,
        statusLabel: String = "Open",
        isOpen: Bool = true
    ) {
        self.id = id
        self.name = name
        self.categoryLabel = categoryLabel
        self.systemImage = systemImage
        self.detail = detail
        self.statusLabel = statusLabel
        self.isOpen = isOpen
    }
}

struct OpenNowWidgetSnapshot: Codable, Equatable, Sendable {
    var baseID: String
    var baseName: String
    var items: [OpenNowWidgetItemSnapshot]
    var bookmarks: [OpenNowWidgetItemSnapshot]
    var updatedAt: Date

    var openCount: Int { items.count }

    var summaryText: String {
        switch openCount {
        case 0: "Nothing open right now"
        case 1: "1 place open"
        default: "\(openCount) places open"
        }
    }

    func bookmark(for id: String) -> OpenNowWidgetItemSnapshot? {
        bookmarks.first { $0.id == id }
    }
}
