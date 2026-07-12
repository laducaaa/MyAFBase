package com.ryanladuca.myafbase

import com.ryanladuca.myafbase.domain.logic.LeavePlannedTrip
import java.time.LocalDate
import java.time.ZoneId

/**
 * Shared iOS parity fixtures from PFRAScoringTests, PFRAGoalPlannerTests, and LeavePlannerTests.
 */
object ParityFixtures {
    val testZone: ZoneId = ZoneId.of("UTC")

    fun localDate(year: Int, month: Int, day: Int): LocalDate = LocalDate.of(year, month, day)

    fun millis(year: Int, month: Int, day: Int): Long =
        localDate(year, month, day).atStartOfDay(testZone).toInstant().toEpochMilli()

    val leaveReferenceDate: LocalDate = localDate(2026, 6, 1)
    val leaveReferenceMillis: Long = millis(2026, 6, 1)

    val pcsDate: LocalDate = localDate(2026, 10, 1)
    val pcsDateMillis: Long = millis(2026, 10, 1)

    fun thanksgivingTrip(): LeavePlannedTrip = LeavePlannedTrip(
        id = "thanksgiving",
        label = "Thanksgiving",
        startMillis = millis(2026, 11, 26),
        endMillis = millis(2026, 11, 30)
    )

    fun christmasTrip(): LeavePlannedTrip = LeavePlannedTrip(
        id = "christmas",
        label = "Christmas",
        startMillis = millis(2026, 12, 23),
        endMillis = millis(2026, 12, 27)
    )

    fun thanksgivingOverlapTrip(): LeavePlannedTrip = LeavePlannedTrip(
        id = "thanksgiving-overlap",
        label = "Thanksgiving",
        startMillis = millis(2026, 11, 20),
        endMillis = millis(2026, 11, 30)
    )

    fun christmasOverlapTrip(): LeavePlannedTrip = LeavePlannedTrip(
        id = "christmas-overlap",
        label = "Christmas",
        startMillis = millis(2026, 12, 20),
        endMillis = millis(2026, 12, 31)
    )

    /** Manual side-by-side vector: male 28, 72" height, 34" waist, 13:30 run, 55 push-ups, 50 sit-ups */
    object StrongPassMale28 {
        const val COMPOSITE = 94.06140350877193
        const val CARDIO = 50.0
        const val BODY = 20.0
        const val STRENGTH = 12.06140350877193
        const val CORE = 12.0
    }
}
