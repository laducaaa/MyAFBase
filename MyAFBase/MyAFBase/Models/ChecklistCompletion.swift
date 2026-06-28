import Foundation
import SwiftData

@Model
final class ChecklistCompletion {
    var baseID: String = ""
    var itemID: String = ""
    var kind: String = ""
    var completedAt: Date = Date()

    init(baseID: String, itemID: String, kind: String, completedAt: Date = Date()) {
        self.baseID = baseID
        self.itemID = itemID
        self.kind = kind
        self.completedAt = completedAt
    }
}
