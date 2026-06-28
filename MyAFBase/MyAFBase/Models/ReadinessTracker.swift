import Foundation
import SwiftData

@Model
final class ReadinessTracker {
    var baseID: String = ""
    var fitnessTestDue: Date?
    var dentalDue: Date?
    var evalCloseoutDue: Date?
    var pcsWindowStart: Date?
    var pcsWindowEnd: Date?
    var cacExpiration: Date?
    var clearanceRenewal: Date?
    var updatedAt: Date = Date()

    init(
        baseID: String,
        fitnessTestDue: Date? = nil,
        dentalDue: Date? = nil,
        evalCloseoutDue: Date? = nil,
        pcsWindowStart: Date? = nil,
        pcsWindowEnd: Date? = nil,
        cacExpiration: Date? = nil,
        clearanceRenewal: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.baseID = baseID
        self.fitnessTestDue = fitnessTestDue
        self.dentalDue = dentalDue
        self.evalCloseoutDue = evalCloseoutDue
        self.pcsWindowStart = pcsWindowStart
        self.pcsWindowEnd = pcsWindowEnd
        self.cacExpiration = cacExpiration
        self.clearanceRenewal = clearanceRenewal
        self.updatedAt = updatedAt
    }
}
