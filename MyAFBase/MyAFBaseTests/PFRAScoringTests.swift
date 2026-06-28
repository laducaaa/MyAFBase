import Foundation
import Testing
@testable import MyAFBase

struct PFRAScoringTests {
    @Test func whtrScoresMaximumAtLowRatio() {
        let result = PFRAScoring.evaluate(
            gender: .male,
            age: 25,
            heightInches: 72,
            waistInches: 34,
            cardioEvent: .twoMileRun,
            cardioValue: 14 * 60,
            strengthEvent: .pushUps,
            strengthReps: 50,
            coreEvent: .sitUps,
            coreValue: 50
        )

        let body = result.componentScores.first(where: { $0.name == "Body Composition" })
        #expect(body?.points == 20)
        #expect(body?.passed == true)
    }

    @Test func whtrFailsAtOrAbove060() {
        let result = PFRAScoring.evaluate(
            gender: .male,
            age: 25,
            heightInches: 70,
            waistInches: 42,
            cardioEvent: .twoMileRun,
            cardioValue: 14 * 60,
            strengthEvent: .pushUps,
            strengthReps: 50,
            coreEvent: .sitUps,
            coreValue: 50
        )

        let body = result.componentScores.first(where: { $0.name == "Body Composition" })
        #expect(body?.points == 0)
        #expect(body?.passed == false)
        #expect(result.passed == false)
    }

    @Test func strongPerformanceCanPass() {
        let result = PFRAScoring.evaluate(
            gender: .male,
            age: 28,
            heightInches: 72,
            waistInches: 34,
            cardioEvent: .twoMileRun,
            cardioValue: 13 * 60 + 30,
            strengthEvent: .pushUps,
            strengthReps: 55,
            coreEvent: .sitUps,
            coreValue: 50
        )

        #expect(result.compositeScore >= 75)
        #expect(result.passed == true)
    }

    @Test func parsesRunTime() {
        #expect(PFRAScoring.parseRunTime("13:25") == 805)
        #expect(PFRAScoring.parseRunTime("15:00") == 900)
    }
}
