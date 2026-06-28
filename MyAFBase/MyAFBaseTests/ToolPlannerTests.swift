import Foundation
import Testing
@testable import MyAFBase

struct PFRAGoalPlannerTests {
    @Test func goalPlannerIdentifiesCardioGap() {
        let plan = PFRAGoalPlanner.plan(
            target: .satisfactory,
            gender: .male,
            age: 28,
            heightInches: 72,
            waistInches: 34,
            cardioEvent: .twoMileRun,
            cardioValue: 22 * 60,
            strengthEvent: .pushUps,
            strengthReps: 35,
            coreEvent: .sitUps,
            coreValue: 35
        )

        guard let plan else {
            Issue.record("Expected a goal plan result")
            return
        }

        #expect(plan.alreadyMet == false)
        #expect(plan.currentComposite < 75)
        let cardio = plan.componentTargets.first(where: { $0.name == "Cardio" })
        #expect(cardio?.needsImprovement == true)
    }

    @Test func reverseCardioLookupFindsRunTime() {
        let ageGroup = PFRAgeGroup.from(age: 25)
        let targetPoints = PFRAScoring.cardioMinimum
        let performance = PFRAScoring.performanceForCardioPoints(
            gender: .male,
            ageGroup: ageGroup,
            event: .twoMileRun,
            targetPoints: targetPoints
        )

        guard let performance else {
            Issue.record("Expected a reverse cardio lookup result")
            return
        }

        let points = PFRAScoring.cardioPoints(
            gender: .male,
            ageGroup: ageGroup,
            event: .twoMileRun,
            value: performance
        )
        #expect(points >= targetPoints)
    }
}

struct LeavePlannerTests {
    @Test func leavePlannerCalculatesExcess() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let pcs = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!

        let plan = LeavePlanner.plan(
            currentBalance: 75,
            pcsDate: pcs,
            maxBalanceAtPCS: 60,
            from: today,
            calendar: calendar
        )

        #expect(plan?.excessLeave == 15)
        #expect(plan?.needsUsagePlan == true)
        #expect(plan?.daysUntilPCS == 122)
    }

    @Test func leavePlannerNoExcessWhenUnderCap() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let pcs = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!

        let plan = LeavePlanner.plan(
            currentBalance: 45,
            pcsDate: pcs,
            maxBalanceAtPCS: 60,
            from: today,
            calendar: calendar
        )

        #expect(plan?.excessLeave == 0)
        #expect(plan?.needsUsagePlan == false)
    }

    @Test func tripCoverageProjectsAccrualBeforeDecemberTrip() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let leaveStart = calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        let leaveEnd = calendar.date(from: DateComponents(year: 2026, month: 12, day: 14))!

        let coverage = LeavePlanner.evaluateTripCoverage(
            currentBalance: 5,
            leaveStartDate: leaveStart,
            leaveEndDate: leaveEnd,
            accrualPerMonth: 2.5,
            from: today,
            calendar: calendar
        )

        #expect(coverage?.leaveDays == 14)
        #expect(coverage?.isCovered == true)
        #expect(coverage?.projectedBalance ?? 0 >= 14)
    }

    @Test func leaveDaysCountsInclusiveRange() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 12, day: 14))!

        #expect(LeavePlanner.leaveDays(from: start, to: end, calendar: calendar) == 14)
    }

    @Test func tripCoverageShowsShortfallForNearTermTrip() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let leaveStart = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20))!
        let leaveEnd = calendar.date(from: DateComponents(year: 2026, month: 7, day: 3))!

        let coverage = LeavePlanner.evaluateTripCoverage(
            currentBalance: 5,
            leaveStartDate: leaveStart,
            leaveEndDate: leaveEnd,
            accrualPerMonth: 2.5,
            from: today,
            calendar: calendar
        )

        #expect(coverage?.leaveDays == 14)
        #expect(coverage?.isCovered == false)
        #expect(coverage?.shortfall ?? 0 > 0)
    }
}
