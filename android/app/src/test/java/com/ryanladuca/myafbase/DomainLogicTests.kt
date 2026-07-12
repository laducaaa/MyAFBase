package com.ryanladuca.myafbase

import com.ryanladuca.myafbase.domain.logic.BaseCatalog
import com.ryanladuca.myafbase.domain.logic.HoursParser
import com.ryanladuca.myafbase.domain.logic.LeavePlanner
import com.ryanladuca.myafbase.domain.logic.LeavePlannedTrip
import com.ryanladuca.myafbase.domain.logic.OpenStatus
import com.ryanladuca.myafbase.domain.logic.PCSChecklist
import com.ryanladuca.myafbase.domain.logic.PCSChecklistKind
import com.ryanladuca.myafbase.domain.logic.PFRAgeGroup
import com.ryanladuca.myafbase.domain.logic.PFRACardioEvent
import com.ryanladuca.myafbase.domain.logic.PFRACoreEvent
import com.ryanladuca.myafbase.domain.logic.PFRAGender
import com.ryanladuca.myafbase.domain.logic.PFRAGoalPlanner
import com.ryanladuca.myafbase.domain.logic.PFRAScoring
import com.ryanladuca.myafbase.domain.logic.PFRAStrengthEvent
import com.ryanladuca.myafbase.domain.logic.PFRATargetTier
import com.ryanladuca.myafbase.domain.logic.PFRATrends
import com.ryanladuca.myafbase.domain.logic.PayCalendar
import com.ryanladuca.myafbase.domain.logic.PayEventKind
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.BaseIndexEntry
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.concurrent.TimeUnit

class DomainLogicTests {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true; coerceInputValues = true }

    @Test
    fun hoursParserDetects247() {
        val parsed = HoursParser.parse("Open 24/7")
        assertEquals(OpenStatus.ALWAYS_OPEN, parsed.status)
        assertEquals(true, HoursParser.isOpenNow("Open 24/7"))
    }

    @Test
    fun hoursParserMonFri() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.YEAR, 2026)
            set(Calendar.MONTH, Calendar.JULY)
            set(Calendar.DAY_OF_MONTH, 8) // Wednesday
            set(Calendar.HOUR_OF_DAY, 10)
            set(Calendar.MINUTE, 0)
        }
        val parsed = HoursParser.parse("Mon-Fri 0600-1700", cal.timeInMillis)
        assertEquals(OpenStatus.OPEN, parsed.status)
    }

    @Test
    fun baseCatalogSanitizeAndConus() {
        assertEquals("altus", BaseCatalog.sanitize(" Altus "))
        assertEquals(null, BaseCatalog.sanitize("../evil"))
        val index = listOf(
            BaseIndexEntry("altus", "Altus AFB", "OK", "97 AMW", "conus"),
            BaseIndexEntry("aviano", "Aviano AB", "Italy", "31 FW", "oconus")
        )
        assertEquals(1, BaseCatalog.conusBases(index).size)
    }

    @Test
    fun pcsChecklistCounts() {
        assertEquals(12, PCSChecklist.items(PCSChecklistKind.INBOUND).size)
        assertEquals(10, PCSChecklist.items(PCSChecklistKind.OUTBOUND).size)
    }

    @Test
    fun payCalendarWeekendAdjust() {
        val saturday = Calendar.getInstance().apply {
            set(2026, Calendar.JULY, 4, 0, 0, 0) // Saturday
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val adjusted = PayCalendar.adjustedPayday(saturday)
        val cal = Calendar.getInstance().apply { timeInMillis = adjusted }
        assertEquals(Calendar.FRIDAY, cal.get(Calendar.DAY_OF_WEEK))
        val events = PayCalendar.upcomingEvents(monthsAhead = 2)
        assertTrue(events.any { it.kind == PayEventKind.MID_MONTH })
        assertTrue(events.any { it.kind == PayEventKind.MONTH_END })
    }

    @Test
    fun leavePlannerCoversExistingBalance() {
        val start = System.currentTimeMillis() + 10L * 24 * 60 * 60 * 1000
        val end = start + 4L * 24 * 60 * 60 * 1000
        val result = LeavePlanner.evaluateTripCoverage(20.0, start, end)
        assertNotNull(result)
        assertTrue(result!!.isCovered)
        assertEquals(5.0, result.leaveDays, 0.01)
    }

    @Test
    fun leavePlannerProjectsBalanceAndMultiTrip() {
        val now = Calendar.getInstance().apply {
            set(2026, Calendar.JANUARY, 1, 12, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val target = now + TimeUnit.DAYS.toMillis(30)
        val projection = LeavePlanner.projectBalance(10.0, target, referenceMillis = now)
        assertNotNull(projection)
        assertTrue(projection!!.projectedBalance > 10.0)

        val trip1Start = now + TimeUnit.DAYS.toMillis(20)
        val trip1End = trip1Start + TimeUnit.DAYS.toMillis(2)
        val trip2Start = now + TimeUnit.DAYS.toMillis(40)
        val trip2End = trip2Start + TimeUnit.DAYS.toMillis(2)
        val multi = LeavePlanner.evaluateMultipleTrips(
            currentBalance = 15.0,
            trips = listOf(
                LeavePlannedTrip("a", "Trip A", trip1Start, trip1End),
                LeavePlannedTrip("b", "Trip B", trip2Start, trip2End)
            ),
            referenceMillis = now
        )
        assertNotNull(multi)
        assertEquals(2, multi!!.evaluations.size)
        assertTrue(multi.allCovered)
    }

    @Test
    fun leavePlannerPcsPlanFlagsOverCap() {
        val now = Calendar.getInstance().apply {
            set(2026, Calendar.JANUARY, 1, 12, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val pcs = now + TimeUnit.DAYS.toMillis(60)
        val plan = LeavePlanner.plan(
            currentBalance = 75.0,
            pcsDateMillis = pcs,
            maxBalanceAtPcs = 60.0,
            referenceMillis = now
        )
        assertNotNull(plan)
        assertTrue(plan!!.excessLeave > 0)
        assertTrue(plan.notes.any { it.contains("per month") })
        assertTrue(plan.milestones.isNotEmpty())
    }

    @Test
    fun payCalendarInsightsDetectGaps() {
        val events = PayCalendar.upcomingEvents(monthsAhead = 4)
        assertTrue(events.size >= 2)
        val gaps = PayCalendar.payGaps(events)
        assertTrue(gaps.isNotEmpty())
        val notes = PayCalendar.insights(events)
        assertTrue(notes.isNotEmpty())
    }

    @Test
    fun pfraTrendsSummarizeNewestFirst() {
        val empty = PFRATrends.summarize(emptyList())
        assertEquals(0, empty.count)
        assertNull(empty.bestScore)

        val summary = PFRATrends.summarize(
            listOf(90.0 to true, 85.0 to true, 70.0 to false)
        )
        assertEquals(3, summary.count)
        assertEquals(90.0, summary.bestScore!!, 0.01)
        assertEquals(90.0, summary.latestScore!!, 0.01)
        assertEquals(5.0, summary.deltaFromPrevious!!, 0.01)
        assertEquals(2, summary.passStreak)
        assertEquals(81.666, summary.averageScore!!, 0.01)
        assertEquals(2.0 / 3.0, summary.passRate!!, 0.01)
    }

    @Test
    fun pfraGoalPlannerProducesGaps() {
        val plan = PFRAGoalPlanner.plan(
            target = PFRATargetTier.EXCELLENT,
            gender = PFRAGender.MALE,
            age = 28,
            heightInches = 70.0,
            waistInches = 32.0,
            cardioEvent = PFRACardioEvent.TWO_MILE_RUN,
            cardioValue = 900.0,
            strengthEvent = PFRAStrengthEvent.PUSH_UPS,
            strengthReps = 45,
            coreEvent = PFRACoreEvent.SIT_UPS,
            coreValue = 45.0
        )
        assertNotNull(plan)
        assertEquals(PFRATargetTier.EXCELLENT, plan!!.target)
        assertEquals(4, plan.componentTargets.size)
    }

    @Test
    fun pfraWhtrScoresMaximumAtLowRatio() {
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
    fun pfraWhtrFailsAtOrAbove060() {
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
    fun pfraStrongPerformanceCanPass() {
        val result = PFRAScoring.evaluate(
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
        assertTrue(result.compositeScore >= 75.0)
        assertTrue(result.passed)
    }

    @Test
    fun pfraParseRunTime() {
        assertEquals(805.0, PFRAScoring.parseRunTime("13:25")!!, 0.01)
        assertEquals(900.0, PFRAScoring.parseRunTime("15:00")!!, 0.01)
    }

    @Test
    fun pfraGoalPlannerIdentifiesCardioGap() {
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
        assertTrue(cardio.targetDetail.contains("Run 2-mile"))
    }

    @Test
    fun pfraReverseCardioLookupFindsRunTime() {
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
    fun pfraScoringProducesResult() {
        val result = PFRAScoring.evaluate(
            gender = PFRAGender.MALE,
            age = 28,
            heightInches = 70.0,
            waistInches = 32.0,
            cardioEvent = PFRACardioEvent.TWO_MILE_RUN,
            cardioValue = 900.0,
            strengthEvent = PFRAStrengthEvent.PUSH_UPS,
            strengthReps = 45,
            coreEvent = PFRACoreEvent.SIT_UPS,
            coreValue = 45.0
        )
        assertTrue(result.compositeScore > 0)
        assertEquals(4, result.componentScores.size)
    }

    @Test
    fun decodesAltusLikeBaseJson() {
        val sample = """
            {
              "id": "altus",
              "name": "Altus AFB",
              "fullName": "Altus Air Force Base",
              "location": "Altus, OK",
              "description": "Test",
              "wing": "97 AMW",
              "latitude": 34.6,
              "longitude": -99.2,
              "emergencyNumbers": [],
              "gates": [{"id":"g1","name":"Main","status":"open","hours":"Open 24/7","traffic":"high"}],
              "resources": [],
              "events": [],
              "newcomers": {"sections": []}
            }
        """.trimIndent()
        val base = json.decodeFromString<Base>(sample)
        assertEquals("altus", base.id)
        assertEquals(1, base.gates.size)
        assertFalse(HoursParser.isOpenNow(base.gates.first().hours) == false)
    }

    @Test
    fun decodesIndexEntry() {
        val sample = """[{"id":"altus","name":"Altus AFB","location":"Altus, OK","wing":"97 AMW","region":"conus"}]"""
        val index = json.decodeFromString<List<BaseIndexEntry>>(sample)
        assertEquals("conus", index.first().region)
    }
}
