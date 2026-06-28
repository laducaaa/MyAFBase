import Foundation
import SwiftData

@Model
final class Bookmark {
    var baseID: String = ""
    var itemID: String = ""
    var itemType: String = ""
    var createdAt: Date = Date()

    init(baseID: String, itemID: String, itemType: String, createdAt: Date = Date()) {
        self.baseID = baseID
        self.itemID = itemID
        self.itemType = itemType
        self.createdAt = createdAt
    }
}
