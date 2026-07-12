import Foundation
import SwiftData
import SwiftUI

enum PFRARecordKind: String, CaseIterable, Identifiable, Codable {
    case diagnostic
    case official
    case goalPlanning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .diagnostic: "Diagnostic"
        case .official: "Official"
        case .goalPlanning: "Goal / Planning"
        }
    }

    var subtitle: String {
        switch self {
        case .diagnostic: "Practice or unofficial check"
        case .official: "Recorded fitness assessment"
        case .goalPlanning: "Working toward a target"
        }
    }

    var systemImage: String {
        switch self {
        case .diagnostic: "stethoscope"
        case .official: "checkmark.seal.fill"
        case .goalPlanning: "target"
        }
    }

    var tint: Color {
        switch self {
        case .diagnostic: AppTheme.info
        case .official: AppTheme.success
        case .goalPlanning: AppTheme.brandPrimary
        }
    }
}

/// A saved PFRA score snapshot. Stored on-device only — fitness data stays local.
@Model
final class PFRARecord {
    var id: UUID = UUID()
    var testedAt: Date = Date()
    var note: String?
    var kindRaw: String = PFRARecordKind.diagnostic.rawValue
    var targetTierRaw: String?

    var genderRaw: String = PFRAGender.male.rawValue
    var age: Int = 25
    var heightInches: Double = 69
    var waistInches: Double = 32

    var cardioEventRaw: String = PFRACardioEvent.twoMileRun.rawValue
    var cardioValue: Double = 900
    var strengthEventRaw: String = PFRAStrengthEvent.pushUps.rawValue
    var strengthReps: Int = 40
    var coreEventRaw: String = PFRACoreEvent.sitUps.rawValue
    var coreValue: Double = 45

    var compositeScore: Double = 0
    var passed: Bool = false
    var rating: String = "Unsatisfactory"

    var bodyPoints: Double = 0
    var bodyPassed: Bool = false
    var bodyDetail: String = ""

    var cardioPoints: Double = 0
    var cardioPassed: Bool = false
    var cardioDetail: String = ""

    var strengthPoints: Double = 0
    var strengthPassed: Bool = false
    var strengthDetail: String = ""

    var corePoints: Double = 0
    var corePassed: Bool = false
    var coreDetail: String = ""

    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        testedAt: Date = Date(),
        note: String? = nil,
        kind: PFRARecordKind = .diagnostic,
        targetTier: PFRATargetTier? = nil,
        gender: PFRAGender,
        age: Int,
        heightInches: Double,
        waistInches: Double,
        cardioEvent: PFRACardioEvent,
        cardioValue: Double,
        strengthEvent: PFRAStrengthEvent,
        strengthReps: Int,
        coreEvent: PFRACoreEvent,
        coreValue: Double,
        result: PFRAResult,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.testedAt = testedAt
        self.note = note
        self.kindRaw = kind.rawValue
        self.targetTierRaw = targetTier?.rawValue
        self.genderRaw = gender.rawValue
        self.age = age
        self.heightInches = heightInches
        self.waistInches = waistInches
        self.cardioEventRaw = cardioEvent.rawValue
        self.cardioValue = cardioValue
        self.strengthEventRaw = strengthEvent.rawValue
        self.strengthReps = strengthReps
        self.coreEventRaw = coreEvent.rawValue
        self.coreValue = coreValue
        self.compositeScore = result.compositeScore
        self.passed = result.passed
        self.rating = result.rating
        self.createdAt = createdAt

        let body = result.componentScores.first { $0.name == "Body Composition" }
        self.bodyPoints = body?.points ?? 0
        self.bodyPassed = body?.passed ?? false
        self.bodyDetail = body?.detail ?? ""

        let cardio = result.componentScores.first { $0.name == "Cardio" }
        self.cardioPoints = cardio?.points ?? 0
        self.cardioPassed = cardio?.passed ?? false
        self.cardioDetail = cardio?.detail ?? ""

        let strength = result.componentScores.first { $0.name == "Strength" }
        self.strengthPoints = strength?.points ?? 0
        self.strengthPassed = strength?.passed ?? false
        self.strengthDetail = strength?.detail ?? ""

        let core = result.componentScores.first { $0.name == "Core" }
        self.corePoints = core?.points ?? 0
        self.corePassed = core?.passed ?? false
        self.coreDetail = core?.detail ?? ""
    }

    var kind: PFRARecordKind {
        get { PFRARecordKind(rawValue: kindRaw) ?? .diagnostic }
        set { kindRaw = newValue.rawValue }
    }

    var gender: PFRAGender {
        get { PFRAGender(rawValue: genderRaw) ?? .male }
        set { genderRaw = newValue.rawValue }
    }

    var cardioEvent: PFRACardioEvent {
        get { PFRACardioEvent(rawValue: cardioEventRaw) ?? .twoMileRun }
        set { cardioEventRaw = newValue.rawValue }
    }

    var strengthEvent: PFRAStrengthEvent {
        get { PFRAStrengthEvent(rawValue: strengthEventRaw) ?? .pushUps }
        set { strengthEventRaw = newValue.rawValue }
    }

    var coreEvent: PFRACoreEvent {
        get { PFRACoreEvent(rawValue: coreEventRaw) ?? .sitUps }
        set { coreEventRaw = newValue.rawValue }
    }

    var targetTier: PFRATargetTier? {
        get { targetTierRaw.flatMap(PFRATargetTier.init(rawValue:)) }
        set { targetTierRaw = newValue?.rawValue }
    }

    var componentSummaries: [(name: String, points: Double, passed: Bool, detail: String)] {
        [
            ("Body Composition", bodyPoints, bodyPassed, bodyDetail),
            ("Cardio", cardioPoints, cardioPassed, cardioDetail),
            ("Strength", strengthPoints, strengthPassed, strengthDetail),
            ("Core", corePoints, corePassed, coreDetail)
        ]
    }
}
