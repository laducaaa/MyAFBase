import Foundation
import Observation

/// Shared PFRA inputs for Score Calculator and Goal Planner.
/// Persisted in `UserDefaults` so edits in one tool carry into the other.
@Observable
@MainActor
final class PFRAProfileStore {
    private enum Keys {
        static let gender = "pfraProfile.gender"
        static let age = "pfraProfile.age"
        static let heightFeet = "pfraProfile.heightFeet"
        static let heightInches = "pfraProfile.heightInches"
        static let waistTenths = "pfraProfile.waistTenths"
        static let cardioEvent = "pfraProfile.cardioEvent"
        static let runMinutes = "pfraProfile.runMinutes"
        static let runSeconds = "pfraProfile.runSeconds"
        static let hamrShuttles = "pfraProfile.hamrShuttles"
        static let strengthEvent = "pfraProfile.strengthEvent"
        static let strengthReps = "pfraProfile.strengthReps"
        static let coreEvent = "pfraProfile.coreEvent"
        static let coreReps = "pfraProfile.coreReps"
        static let plankMinutes = "pfraProfile.plankMinutes"
        static let plankSeconds = "pfraProfile.plankSeconds"
        static let targetTier = "pfraProfile.targetTier"
    }

    var gender: PFRAGender {
        didSet { defaults.set(gender.rawValue, forKey: Keys.gender) }
    }

    var age: Int {
        didSet { defaults.set(age, forKey: Keys.age) }
    }

    var heightFeet: Int {
        didSet { defaults.set(heightFeet, forKey: Keys.heightFeet) }
    }

    var heightInches: Int {
        didSet { defaults.set(heightInches, forKey: Keys.heightInches) }
    }

    var waistTenths: Int {
        didSet { defaults.set(waistTenths, forKey: Keys.waistTenths) }
    }

    var cardioEvent: PFRACardioEvent {
        didSet { defaults.set(cardioEvent.rawValue, forKey: Keys.cardioEvent) }
    }

    var runMinutes: Int {
        didSet { defaults.set(runMinutes, forKey: Keys.runMinutes) }
    }

    var runSeconds: Int {
        didSet { defaults.set(runSeconds, forKey: Keys.runSeconds) }
    }

    var hamrShuttles: Int {
        didSet { defaults.set(hamrShuttles, forKey: Keys.hamrShuttles) }
    }

    var strengthEvent: PFRAStrengthEvent {
        didSet { defaults.set(strengthEvent.rawValue, forKey: Keys.strengthEvent) }
    }

    var strengthReps: Int {
        didSet { defaults.set(strengthReps, forKey: Keys.strengthReps) }
    }

    var coreEvent: PFRACoreEvent {
        didSet { defaults.set(coreEvent.rawValue, forKey: Keys.coreEvent) }
    }

    var coreReps: Int {
        didSet { defaults.set(coreReps, forKey: Keys.coreReps) }
    }

    var plankMinutes: Int {
        didSet { defaults.set(plankMinutes, forKey: Keys.plankMinutes) }
    }

    var plankSeconds: Int {
        didSet { defaults.set(plankSeconds, forKey: Keys.plankSeconds) }
    }

    var targetTier: PFRATargetTier {
        didSet { defaults.set(targetTier.rawValue, forKey: Keys.targetTier) }
    }

    var heightTotalInches: Double {
        Double(heightFeet * 12 + heightInches)
    }

    var waistInches: Double {
        Double(waistTenths) / 10.0
    }

    var cardioValue: Double {
        switch cardioEvent {
        case .twoMileRun:
            Double(runMinutes * 60 + runSeconds)
        case .hamr:
            Double(hamrShuttles)
        }
    }

    var coreValue: Double {
        switch coreEvent {
        case .sitUps, .crossLegReverseCrunch:
            Double(coreReps)
        case .forearmPlank:
            Double(plankMinutes * 60 + plankSeconds)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        gender = defaults.string(forKey: Keys.gender).flatMap(PFRAGender.init(rawValue:)) ?? .male
        age = Self.int(defaults, Keys.age, default: 25)
        heightFeet = Self.int(defaults, Keys.heightFeet, default: 5)
        heightInches = Self.int(defaults, Keys.heightInches, default: 9)
        waistTenths = Self.int(defaults, Keys.waistTenths, default: 320)
        cardioEvent = defaults.string(forKey: Keys.cardioEvent).flatMap(PFRACardioEvent.init(rawValue:)) ?? .twoMileRun
        runMinutes = Self.int(defaults, Keys.runMinutes, default: 15)
        runSeconds = Self.int(defaults, Keys.runSeconds, default: 0)
        hamrShuttles = Self.int(defaults, Keys.hamrShuttles, default: 50)
        strengthEvent = defaults.string(forKey: Keys.strengthEvent).flatMap(PFRAStrengthEvent.init(rawValue:)) ?? .pushUps
        strengthReps = Self.int(defaults, Keys.strengthReps, default: 40)
        coreEvent = defaults.string(forKey: Keys.coreEvent).flatMap(PFRACoreEvent.init(rawValue:)) ?? .sitUps
        coreReps = Self.int(defaults, Keys.coreReps, default: 45)
        plankMinutes = Self.int(defaults, Keys.plankMinutes, default: 2)
        plankSeconds = Self.int(defaults, Keys.plankSeconds, default: 0)
        targetTier = defaults.string(forKey: Keys.targetTier).flatMap(PFRATargetTier.init(rawValue:)) ?? .satisfactory
    }

    func clampHeightInches() {
        if heightFeet == 7 {
            heightInches = min(heightInches, 11)
        }
    }

    private static func int(_ defaults: UserDefaults, _ key: String, default fallback: Int) -> Int {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.integer(forKey: key)
    }
}
