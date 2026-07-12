import Foundation
import Testing
@testable import MyAFBase

struct PFRAProfileStoreTests {
    @Test func persistsSharedInputsAcrossInstances() {
        let suiteName = "PFRAProfileStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = PFRAProfileStore(defaults: defaults)
        first.gender = .female
        first.age = 31
        first.heightFeet = 5
        first.heightInches = 6
        first.waistTenths = 285
        first.cardioEvent = .hamr
        first.hamrShuttles = 62
        first.strengthEvent = .handReleasePushUps
        first.strengthReps = 28
        first.coreEvent = .forearmPlank
        first.plankMinutes = 2
        first.plankSeconds = 15
        first.targetTier = .excellent

        let second = PFRAProfileStore(defaults: defaults)
        #expect(second.gender == .female)
        #expect(second.age == 31)
        #expect(second.heightFeet == 5)
        #expect(second.heightInches == 6)
        #expect(second.waistTenths == 285)
        #expect(second.cardioEvent == .hamr)
        #expect(second.hamrShuttles == 62)
        #expect(second.strengthEvent == .handReleasePushUps)
        #expect(second.strengthReps == 28)
        #expect(second.coreEvent == .forearmPlank)
        #expect(second.plankMinutes == 2)
        #expect(second.plankSeconds == 15)
        #expect(second.targetTier == .excellent)
        #expect(second.cardioValue == 62)
        #expect(second.coreValue == 135)
    }
}
