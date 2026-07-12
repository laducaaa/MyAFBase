import Foundation
import SwiftData

@Model
final class AssignmentProfile {
    var baseID: String = ""
    var phaseRaw: String = AssignmentSegment.stationed.rawValue
    var reportDate: Date?
    var pcsDate: Date?
    var updatedAt: Date = Date()

    init(
        baseID: String,
        phaseRaw: String = AssignmentSegment.stationed.rawValue,
        reportDate: Date? = nil,
        pcsDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.baseID = baseID
        self.phaseRaw = phaseRaw
        self.reportDate = reportDate
        self.pcsDate = pcsDate
        self.updatedAt = updatedAt
    }

    var phase: AssignmentSegment {
        get { AssignmentSegment(rawValue: phaseRaw) ?? .stationed }
        set { phaseRaw = newValue.rawValue }
    }
}
