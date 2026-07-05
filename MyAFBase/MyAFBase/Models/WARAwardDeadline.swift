import Foundation
import SwiftData

/// A due date the user is tracking toward (monthly/quarterly award, package
/// suspense, EPB/OPB closeout reminder, etc). Stored on-device only,
/// alongside `WAREntry`.
@Model
final class WARAwardDeadline {
    var id: UUID = UUID()
    var baseID: String = ""
    var title: String = ""
    var dueDate: Date = Date()
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        baseID: String,
        title: String,
        dueDate: Date,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.baseID = baseID
        self.title = title
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var daysUntilDue: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var isPastDue: Bool {
        daysUntilDue < 0
    }
}
