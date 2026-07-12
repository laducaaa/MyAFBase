package com.ryanladuca.myafbase

import com.ryanladuca.myafbase.domain.logic.LeavePlanner
import com.ryanladuca.myafbase.domain.logic.PFRACardioEvent
import com.ryanladuca.myafbase.domain.logic.PFRACoreEvent
import com.ryanladuca.myafbase.domain.logic.PFRAGender
import com.ryanladuca.myafbase.domain.logic.PFRAGoalPlanner
import com.ryanladuca.myafbase.domain.logic.PFRAgeGroup
import com.ryanladuca.myafbase.domain.logic.PFRAScoring
import com.ryanladuca.myafbase.domain.logic.PFRAStrengthEvent
import com.ryanladuca.myafbase.domain.logic.PFRATargetTier
import com.ryanladuca.myafbase.domain.logic.WarDateMath
import com.ryanladuca.myafbase.data.db.WarEntryEntity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ParityTests {

    // MARK: - PFRA (PFRAScoringTests)

    @Test
    fun whtrScoresMaximumAtLowRatio() {
        val result = PFRAScoring.evaluate(
            gender = PFRAGender.MALE,
            age = 25,
            heightInches = 72.0,
            waistInches = 34.0,
            cardioEvent = PFRACardioEvent.TWO_MILE_RUN,
            cardioValue = 14 * 60.0,
            strengthEvent = PFRAStrengthEvent.PUSH_UPS,
            strengthReps = 50,
            coreEvent = PFRACoreEvent.SIT_UPS,
            coreValue = 50.0
        )
        val body = result.componentScores.first { it.name == "Body Composition" }
        assertEquals(20.0, body.points, 0.01)
        assertTrue(body.passed)
    }

    @Test
    fun whtrFailsAtOrAbove060() {
        val result = PFRAScoring.evaluate(
            gender = PFRAGender.MALE,
            age = 25,
            heightInches = 70.0,
            waistInches = 42.0,
            cardioEvent = PFRACardioEvent.TWO_MILE_RUN,
            cardioValue = 14 * 60.0,
            strengthEvent = PFRAStrengthEvent.PUSH_UPS,
            strengthReps = 50,
            coreEvent = PFRACoreEvent.SIT_UPS,
            coreValue = 50.0
        )
        val body = result.componentScores.first { it.name == "Body Composition" }
        assertEquals(0.0, body.points, 0.01)
        assertFalse(body.passed)
        assertFalse(result.passed)
    }

    @Test
    fun strongPerformanceCanPass() {
        val result = strongPassMale28Result()
        assertTrue(result.compositeScore >= 75.0)
        assertTrue(result.passed)
    }

    @Test
    fun sideBySideStrongPassExactComponentPoints() {
        val result = strongPassMale28Result()
        fun pts(name: String) = result.componentScores.first { it.name == name }.points
        // Locked from PFRAScoring.evaluate — must match iOS for this fixture
        assertEquals(94.06140350877193, result.compositeScore, 0.0001)
        assertEquals(50.0, pts("Cardio"), 0.0001)
        assertEquals(20.0, pts("Body Composition"), 0.0001)
        assertEquals(12.06140350877193, pts("Strength"), 0.0001)
        assertEquals(12.0, pts("Core"), 0.0001)
        assertTrue(result.passed)
    }

    @Test
    fun parsesRunTime() {
        assertEquals(805.0, PFRAScoring.parseRunTime("13:25")!!, 0.01)
        assertEquals(900.0, PFRAScoring.parseRunTime("15:00")!!, 0.01)
    }

    // MARK: - Goal planner (PFRAGoalPlannerTests)

    @Test
    fun goalPlannerIdentifiesCardioGap() {
        val plan = PFRAGoalPlanner.plan(
            target = PFRATargetTier.SATISFACTORY,
            gender = PFRAGender.MALE,
            age = 28,
            heightInches = 72.0,
            waistInches = 34.0,
            cardioEvent = PFRACardioEvent.TWO_MILE_RUN,
            cardioValue = 22 * 60.0,
            strengthEvent = PFRAStrengthEvent.PUSH_UPS,
            strengthReps = 35,
            coreEvent = PFRACoreEvent.SIT_UPS,
            coreValue = 35.0
        )
        assertNotNull(plan)
        assertFalse(plan!!.alreadyMet)
        assertTrue(plan.currentComposite < 75.0)
        val cardio = plan.componentTargets.first { it.name == "Cardio" }
        assertTrue(cardio.needsImprovement)
    }

    @Test
    fun reverseCardioLookupFindsRunTime() {
        val ageGroup = PFRAgeGroup.from(25)
        val performance = PFRAScoring.performanceForCardioPoints(
            gender = PFRAGender.MALE,
            ageGroup = ageGroup,
            event = PFRACardioEvent.TWO_MILE_RUN,
            targetPoints = PFRAScoring.CARDIO_MINIMUM
        )
        assertNotNull(performance)
        val points = PFRAScoring.cardioPoints(
            gender = PFRAGender.MALE,
            ageGroup = ageGroup,
            event = PFRACardioEvent.TWO_MILE_RUN,
            value = performance!!
        )
        assertTrue(points >= PFRAScoring.CARDIO_MINIMUM)
    }

    @Test
    fun goalPlannerReturnsNullForInvalidMeasurements() {
        assertNull(
            PFRAGoalPlanner.plan(
                target = PFRATargetTier.SATISFACTORY,
                gender = PFRAGender.MALE,
                age = 28,
                heightInches = 0.0,
                waistInches = 34.0,
                cardioEvent = PFRACardioEvent.TWO_MILE_RUN,
                cardioValue = 900.0,
                strengthEvent = PFRAStrengthEvent.PUSH_UPS,
                strengthReps = 40,
                coreEvent = PFRACoreEvent.SIT_UPS,
                coreValue = 40.0
            )
        )
    }

    // MARK: - Leave planner (LeavePlannerTests)

    @Test
    fun leavePlannerCalculatesExcess() {
        val plan = LeavePlanner.plan(
            currentBalance = 75.0,
            pcsDateMillis = ParityFixtures.pcsDateMillis,
            maxBalanceAtPcs = 60.0,
            referenceMillis = ParityFixtures.leaveReferenceMillis,
            zoneId = ParityFixtures.testZone
        )
        assertNotNull(plan)
        assertEquals(15.0, plan!!.excessLeave, 0.01)
        assertTrue(plan.needsUsagePlan)
        assertEquals(122, plan.daysUntilPcs)
    }

    @Test
    fun leavePlannerNoExcessWhenUnderCap() {
        val plan = LeavePlanner.plan(
            currentBalance = 45.0,
            pcsDateMillis = ParityFixtures.pcsDateMillis,
            maxBalanceAtPcs = 60.0,
            referenceMillis = ParityFixtures.leaveReferenceMillis,
            zoneId = ParityFixtures.testZone
        )
        assertNotNull(plan)
        assertEquals(0.0, plan!!.excessLeave, 0.01)
        assertFalse(plan.needsUsagePlan)
    }

    @Test
    fun tripCoverageProjectsAccrualBeforeDecemberTrip() {
        val coverage = LeavePlanner.evaluateTripCoverage(
            currentBalance = 5.0,
            leaveStartMillis = ParityFixtures.millis(2026, 12, 1),
            leaveEndMillis = ParityFixtures.millis(2026, 12, 14),
            referenceMillis = ParityFixtures.leaveReferenceMillis,
            zoneId = ParityFixtures.testZone
        )
        assertNotNull(coverage)
        assertEquals(14.0, coverage!!.leaveDays, 0.01)
        assertTrue(coverage.isCovered)
        assertTrue(coverage.projectedBalance >= 14.0)
    }

    @Test
    fun leaveDaysCountsInclusiveRange() {
        assertEquals(
            14,
            LeavePlanner.leaveDays(
                ParityFixtures.millis(2026, 12, 1),
                ParityFixtures.millis(2026, 12, 14),
                ParityFixtures.testZone
            )
        )
    }

    @Test
    fun tripCoverageShowsShortfallForNearTermTrip() {
        val coverage = LeavePlanner.evaluateTripCoverage(
            currentBalance = 5.0,
            leaveStartMillis = ParityFixtures.millis(2026, 6, 20),
            leaveEndMillis = ParityFixtures.millis(2026, 7, 3),
            referenceMillis = ParityFixtures.leaveReferenceMillis,
            zoneId = ParityFixtures.testZone
        )
        assertNotNull(coverage)
        assertEquals(14.0, coverage!!.leaveDays, 0.01)
        assertFalse(coverage.isCovered)
        assertTrue(coverage.shortfall > 0)
    }

    @Test
    fun projectBalanceAccruesBeforeTargetDate() {
        val projection = LeavePlanner.projectBalance(
            currentBalance = 30.0,
            targetDateMillis = ParityFixtures.millis(2026, 10, 4),
            referenceMillis = ParityFixtures.leaveReferenceMillis,
            zoneId = ParityFixtures.testZone
        )
        assertNotNull(projection)
        assertEquals(125, projection!!.daysUntilTarget)
        assertTrue(projection.accruedAmount > 7.0)
        assertTrue(projection.projectedBalance > 37.0)
    }

    @Test
    fun multiTripCoversSequentialHolidays() {
        val result = LeavePlanner.evaluateMultipleTrips(
            currentBalance = 10.0,
            trips = listOf(ParityFixtures.thanksgivingTrip(), ParityFixtures.christmasTrip()),
            referenceMillis = ParityFixtures.leaveReferenceMillis,
            zoneId = ParityFixtures.testZone
        )
        assertNotNull(result)
        assertEquals(2, result!!.evaluations.size)
        assertEquals(10.0, result.totalLeaveDays, 0.01)
        assertTrue(result.allCovered)
        assertTrue(result.finalBalance > 0)
    }

    @Test
    fun multiTripFlagsShortfallOnSecondTrip() {
        val result = LeavePlanner.evaluateMultipleTrips(
            currentBalance = 5.0,
            trips = listOf(
                ParityFixtures.thanksgivingOverlapTrip(),
                ParityFixtures.christmasOverlapTrip()
            ),
            referenceMillis = ParityFixtures.leaveReferenceMillis,
            zoneId = ParityFixtures.testZone
        )
        assertNotNull(result)
        assertFalse(result!!.allCovered)
        assertEquals("Christmas", result.firstFailure?.trip?.label)
    }

    // MARK: - WAR date bucketing

    @Test
    fun warEntryBackdateLandsInCorrectDayBucket() {
        val zone = ParityFixtures.testZone
        val tuesday = ParityFixtures.millis(2026, 7, 7) // Tuesday UTC
        val entry = WarEntryEntity(
            id = "e1",
            baseId = "test",
            dateMillis = tuesday,
            title = "Bullet",
            body = "Did thing",
            category = "mission",
            impact = "",
            tags = "",
            hours = 1.0
        )
        val weekStart = WarDateMath.startOfWeek(tuesday, zone)
        val dayStart = weekStart + 2 * 86_400_000L
        val dayEnd = dayStart + 86_399_999L
        assertTrue(entry.dateMillis in dayStart..dayEnd)
    }

    private fun strongPassMale28Result() = PFRAScoring.evaluate(
        gender = PFRAGender.MALE,
        age = 28,
        heightInches = 72.0,
        waistInches = 34.0,
        cardioEvent = PFRACardioEvent.TWO_MILE_RUN,
        cardioValue = 13 * 60 + 30.0,
        strengthEvent = PFRAStrengthEvent.PUSH_UPS,
        strengthReps = 55,
        coreEvent = PFRACoreEvent.SIT_UPS,
        coreValue = 50.0
    )
}
