package com.ryanladuca.myafbase.domain.logic

import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

data class LeaveTripCoverageResult(
    val leaveStartDateMillis: Long,
    val leaveEndDateMillis: Long,
    val leaveDays: Double,
    val daysUntilLeave: Int,
    val currentBalance: Double,
    val projectedBalance: Double,
    val accruedByLeave: Double,
    val surplus: Double,
    val isCovered: Boolean,
    val notes: List<String>
) {
    val shortfall: Double get() = max(0.0, -surplus)
    val spareDays: Double get() = max(0.0, surplus)
}

data class LeaveBalanceProjectionResult(
    val targetDateMillis: Long,
    val currentBalance: Double,
    val projectedBalance: Double,
    val accruedAmount: Double,
    val daysUntilTarget: Int,
    val hitAccrualCap: Boolean
)

data class LeavePlannedTrip(
    val id: String,
    val label: String,
    val startMillis: Long,
    val endMillis: Long
)

data class LeaveTripEvaluation(
    val trip: LeavePlannedTrip,
    val leaveDays: Double,
    val balanceBefore: Double,
    val balanceAfter: Double,
    val isCovered: Boolean,
    val shortfall: Double
)

data class LeaveMultiTripCoverageResult(
    val startingBalance: Double,
    val evaluations: List<LeaveTripEvaluation>,
    val totalLeaveDays: Double,
    val finalBalance: Double,
    val allCovered: Boolean,
    val firstFailure: LeaveTripEvaluation?,
    val overlapWarnings: List<String>
)

data class LeaveMilestone(
    val dateMillis: Long,
    val title: String,
    val detail: String
)

data class LeavePlanResult(
    val daysUntilPcs: Int,
    val currentBalance: Double,
    val maxBalanceAtPcs: Double,
    val excessLeave: Double,
    val specialLeaveBalance: Double,
    val daysPerWeekToUse: Double,
    val daysPerMonthToUse: Double,
    val milestones: List<LeaveMilestone>,
    val notes: List<String>
) {
    val needsUsagePlan: Boolean get() = excessLeave > 0
}

/** @deprecated Use [LeavePlanResult] via [LeavePlanner.plan] */
data class LeavePcsPlanResult(
    val pcsDateMillis: Long,
    val projectedBalanceAtPcs: Double,
    val maxBalanceAtPcs: Double,
    val overCapBy: Double,
    val recommendations: List<String>
)

object LeavePlanner {
    const val DEFAULT_MAX_BALANCE_AT_PCS = 60.0
    const val FISCAL_YEAR_CARRY_CAP = 60.0
    const val DEFAULT_ACCRUAL_PER_MONTH = 2.5
    const val DEFAULT_MAX_ACCRUING_BALANCE = 60.0
    const val DAYS_PER_ACCRUAL_MONTH = 30.44

    private val dateFormat = DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.US)

    fun leaveDays(
        leaveStartMillis: Long,
        leaveEndMillis: Long,
        zoneId: ZoneId = ZoneId.systemDefault()
    ): Int? {
        val start = toLocalDate(leaveStartMillis, zoneId)
        val end = toLocalDate(leaveEndMillis, zoneId)
        if (end.isBefore(start)) return null
        return ChronoUnit.DAYS.between(start, end).toInt() + 1
    }

    fun evaluateTripCoverage(
        currentBalance: Double,
        leaveStartMillis: Long,
        leaveEndMillis: Long,
        accrualPerMonth: Double = DEFAULT_ACCRUAL_PER_MONTH,
        maxAccruingBalance: Double = DEFAULT_MAX_ACCRUING_BALANCE,
        referenceMillis: Long = System.currentTimeMillis(),
        zoneId: ZoneId = ZoneId.systemDefault()
    ): LeaveTripCoverageResult? {
        if (currentBalance < 0 || accrualPerMonth < 0 || maxAccruingBalance <= 0) return null

        val referenceDate = toLocalDate(referenceMillis, zoneId)
        val startOfLeave = toLocalDate(leaveStartMillis, zoneId)
        val endOfLeave = toLocalDate(leaveEndMillis, zoneId)
        val leaveDayCount = leaveDays(
            toMillis(startOfLeave, zoneId),
            toMillis(endOfLeave, zoneId),
            zoneId
        )

        if (leaveDayCount == null || leaveDayCount <= 0) {
            return LeaveTripCoverageResult(
                leaveStartDateMillis = toMillis(startOfLeave, zoneId),
                leaveEndDateMillis = toMillis(endOfLeave, zoneId),
                leaveDays = 0.0,
                daysUntilLeave = 0,
                currentBalance = currentBalance,
                projectedBalance = currentBalance,
                accruedByLeave = 0.0,
                surplus = currentBalance,
                isCovered = false,
                notes = listOf("End date must be on or after the start date.")
            )
        }

        val requestedDays = leaveDayCount.toDouble()
        val daysUntilLeave = ChronoUnit.DAYS.between(referenceDate, startOfLeave).toInt()

        if (daysUntilLeave < 0) {
            return LeaveTripCoverageResult(
                leaveStartDateMillis = toMillis(startOfLeave, zoneId),
                leaveEndDateMillis = toMillis(endOfLeave, zoneId),
                leaveDays = requestedDays,
                daysUntilLeave = daysUntilLeave,
                currentBalance = currentBalance,
                projectedBalance = currentBalance,
                accruedByLeave = 0.0,
                surplus = currentBalance - requestedDays,
                isCovered = currentBalance >= requestedDays,
                notes = listOf("Leave start date cannot be in the past.")
            )
        }

        val accruedByLeave = if (daysUntilLeave == 0) {
            0.0
        } else {
            accruedLeave(currentBalance, daysUntilLeave, accrualPerMonth, maxAccruingBalance)
        }
        val projectedBalance = min(maxAccruingBalance, currentBalance + accruedByLeave)
        val surplus = projectedBalance - requestedDays
        val isCovered = surplus >= -0.05

        val notes = mutableListOf<String>()
        when {
            currentBalance >= requestedDays ->
                notes += "You already have enough leave today for this period."
            isCovered ->
                notes += "Projected balance on ${formatDate(startOfLeave)} covers ${formattedDays(requestedDays)}."
            else -> {
                notes += "Projected shortfall of ${formattedDays(abs(surplus))} when leave starts on ${formatDate(startOfLeave)}."
                daysUntilLeaveNeeded(currentBalance, requestedDays, accrualPerMonth, maxAccruingBalance)?.let { needed ->
                    if (needed > daysUntilLeave) {
                        notes += "At ${formattedRate(accrualPerMonth)}, you may need roughly $needed more days from today before you have enough."
                    }
                }
            }
        }
        if (projectedBalance >= maxAccruingBalance - 0.05) {
            notes += "Projection assumes accrual slows near the ${maxAccruingBalance.toInt()}-day balance cap."
        }
        notes += "Uses your entered accrual rate. Confirm earnings and caps on your LES with CSS."

        return LeaveTripCoverageResult(
            leaveStartDateMillis = toMillis(startOfLeave, zoneId),
            leaveEndDateMillis = toMillis(endOfLeave, zoneId),
            leaveDays = requestedDays,
            daysUntilLeave = daysUntilLeave,
            currentBalance = currentBalance,
            projectedBalance = projectedBalance,
            accruedByLeave = accruedByLeave,
            surplus = surplus,
            isCovered = isCovered,
            notes = notes
        )
    }

    fun accruedLeave(
        fromBalance: Double,
        daysUntil: Int,
        accrualPerMonth: Double = DEFAULT_ACCRUAL_PER_MONTH,
        maxBalance: Double = DEFAULT_MAX_ACCRUING_BALANCE
    ): Double {
        if (daysUntil <= 0 || accrualPerMonth <= 0 || fromBalance >= maxBalance) return 0.0
        val months = daysUntil / DAYS_PER_ACCRUAL_MONTH
        val uncapped = months * accrualPerMonth
        val roomToCap = max(0.0, maxBalance - fromBalance)
        return min(uncapped, roomToCap)
    }

    fun projectBalance(
        currentBalance: Double,
        targetDateMillis: Long,
        accrualPerMonth: Double = DEFAULT_ACCRUAL_PER_MONTH,
        maxAccruingBalance: Double = DEFAULT_MAX_ACCRUING_BALANCE,
        referenceMillis: Long = System.currentTimeMillis(),
        zoneId: ZoneId = ZoneId.systemDefault()
    ): LeaveBalanceProjectionResult? {
        if (currentBalance < 0 || accrualPerMonth < 0 || maxAccruingBalance <= 0) return null

        val referenceDate = toLocalDate(referenceMillis, zoneId)
        val targetDate = toLocalDate(targetDateMillis, zoneId)
        val daysUntil = ChronoUnit.DAYS.between(referenceDate, targetDate).toInt()

        if (daysUntil < 0) {
            return LeaveBalanceProjectionResult(
                targetDateMillis = toMillis(targetDate, zoneId),
                currentBalance = currentBalance,
                projectedBalance = currentBalance,
                accruedAmount = 0.0,
                daysUntilTarget = daysUntil,
                hitAccrualCap = false
            )
        }

        val accrued = if (daysUntil == 0) 0.0 else accruedLeave(
            currentBalance, daysUntil, accrualPerMonth, maxAccruingBalance
        )
        val projected = min(maxAccruingBalance, currentBalance + accrued)
        return LeaveBalanceProjectionResult(
            targetDateMillis = toMillis(targetDate, zoneId),
            currentBalance = currentBalance,
            projectedBalance = projected,
            accruedAmount = accrued,
            daysUntilTarget = daysUntil,
            hitAccrualCap = projected >= maxAccruingBalance - 0.05 && currentBalance < maxAccruingBalance
        )
    }

    fun evaluateMultipleTrips(
        currentBalance: Double,
        trips: List<LeavePlannedTrip>,
        accrualPerMonth: Double = DEFAULT_ACCRUAL_PER_MONTH,
        maxAccruingBalance: Double = DEFAULT_MAX_ACCRUING_BALANCE,
        referenceMillis: Long = System.currentTimeMillis(),
        zoneId: ZoneId = ZoneId.systemDefault()
    ): LeaveMultiTripCoverageResult? {
        if (currentBalance < 0 || accrualPerMonth < 0 || maxAccruingBalance <= 0 || trips.isEmpty()) {
            return null
        }

        var balance = currentBalance
        var checkpoint = toLocalDate(referenceMillis, zoneId)
        val sorted = trips
            .map {
                val start = toLocalDate(it.startMillis, zoneId)
                val end = maxOf(start, toLocalDate(it.endMillis, zoneId))
                it.copy(
                    startMillis = toMillis(start, zoneId),
                    endMillis = toMillis(end, zoneId)
                )
            }
            .sortedBy { it.startMillis }

        val evaluations = mutableListOf<LeaveTripEvaluation>()
        val warnings = mutableListOf<String>()

        sorted.forEachIndexed { index, trip ->
            val startDate = toLocalDate(trip.startMillis, zoneId)
            val endDate = toLocalDate(trip.endMillis, zoneId)
            val days = leaveDays(trip.startMillis, trip.endMillis, zoneId) ?: return@forEachIndexed
            if (days <= 0) return@forEachIndexed

            if (index > 0) {
                val previous = sorted[index - 1]
                val previousEnd = toLocalDate(previous.endMillis, zoneId)
                if (!startDate.isAfter(previousEnd)) {
                    val name = trip.label.ifBlank { "Trip ${index + 1}" }
                    val prevName = previous.label.ifBlank { "Trip $index" }
                    warnings += "$name overlaps with $prevName."
                }
            }

            if (startDate.isAfter(checkpoint)) {
                val gap = ChronoUnit.DAYS.between(checkpoint, startDate).toInt()
                if (gap > 0) {
                    balance = min(
                        maxAccruingBalance,
                        balance + accruedLeave(balance, gap, accrualPerMonth, maxAccruingBalance)
                    )
                }
            }

            val requestedDays = days.toDouble()
            val balanceAtStart = balance
            val isCovered = balanceAtStart + 0.05 >= requestedDays
            val shortfall = max(0.0, requestedDays - balanceAtStart)
            balance = balanceAtStart - requestedDays

            evaluations += LeaveTripEvaluation(
                trip = trip,
                leaveDays = requestedDays,
                balanceBefore = balanceAtStart,
                balanceAfter = balance,
                isCovered = isCovered,
                shortfall = shortfall
            )

            checkpoint = endDate.plusDays(1)
        }

        if (evaluations.isEmpty()) return null

        return LeaveMultiTripCoverageResult(
            startingBalance = currentBalance,
            evaluations = evaluations,
            totalLeaveDays = evaluations.sumOf { it.leaveDays },
            finalBalance = balance,
            allCovered = evaluations.all { it.isCovered },
            firstFailure = evaluations.firstOrNull { !it.isCovered },
            overlapWarnings = warnings
        )
    }

    fun plan(
        currentBalance: Double,
        pcsDateMillis: Long,
        maxBalanceAtPcs: Double = DEFAULT_MAX_BALANCE_AT_PCS,
        specialLeaveBalance: Double = 0.0,
        specialLeaveExpiresMillis: Long? = null,
        referenceMillis: Long = System.currentTimeMillis(),
        zoneId: ZoneId = ZoneId.systemDefault()
    ): LeavePlanResult? {
        if (currentBalance < 0 || maxBalanceAtPcs < 0 || specialLeaveBalance < 0) return null

        val referenceDate = toLocalDate(referenceMillis, zoneId)
        val pcsDate = toLocalDate(pcsDateMillis, zoneId)
        val daysUntilPcs = ChronoUnit.DAYS.between(referenceDate, pcsDate).toInt()

        if (daysUntilPcs <= 0) {
            return LeavePlanResult(
                daysUntilPcs = daysUntilPcs,
                currentBalance = currentBalance,
                maxBalanceAtPcs = maxBalanceAtPcs,
                excessLeave = 0.0,
                specialLeaveBalance = specialLeaveBalance,
                daysPerWeekToUse = 0.0,
                daysPerMonthToUse = 0.0,
                milestones = emptyList(),
                notes = listOf("PCS date must be in the future to build a usage plan.")
            )
        }

        val notes = mutableListOf<String>()
        val excessLeave = max(0.0, currentBalance - maxBalanceAtPcs)
        val weeksRemaining = max(1.0, daysUntilPcs / 7.0)
        val monthsRemaining = max(1.0, daysUntilPcs / DAYS_PER_ACCRUAL_MONTH)
        val daysPerWeek = excessLeave / weeksRemaining
        val daysPerMonth = excessLeave / monthsRemaining

        if (excessLeave <= 0) {
            notes += "Your balance is at or below the ${maxBalanceAtPcs.toInt()}-day PCS planning cap. No mandatory usage pace is required."
        } else {
            notes += "Use about ${formattedDays(daysPerMonth)} per month (or ${formattedDays(daysPerWeek)} per week) to burn ${formattedDays(excessLeave)} before PCS."
        }

        nextFiscalYearEnd(referenceDate)?.let { fyDeadline ->
            if (fyDeadline.isBefore(pcsDate) && currentBalance > FISCAL_YEAR_CARRY_CAP) {
                val fyExcess = currentBalance - FISCAL_YEAR_CARRY_CAP
                notes += "Fiscal year ends ${formatDate(fyDeadline)}: ${formattedDays(fyExcess)} above the 60-day carryover cap should be used by then or it may be lost."
            }
        }

        if (specialLeaveBalance > 0) {
            val expiration = specialLeaveExpiresMillis?.let { toLocalDate(it, zoneId) }
            when {
                expiration != null && expiration.isBefore(pcsDate) ->
                    notes += "Use ${formattedDays(specialLeaveBalance)} special leave before it expires on ${formatDate(expiration)}."
                expiration != null ->
                    notes += "You have ${formattedDays(specialLeaveBalance)} special leave on the books — confirm expiration with your CSS."
                else ->
                    notes += "You entered ${formattedDays(specialLeaveBalance)} special leave — add an expiration date if it is use-or-lose."
            }
        }

        notes += "Unofficial estimate only. Confirm balances, sell-back rules, and PCS leave limits with your unit CSS."

        val milestones = buildMilestones(excessLeave, daysUntilPcs, referenceDate, zoneId)

        return LeavePlanResult(
            daysUntilPcs = daysUntilPcs,
            currentBalance = currentBalance,
            maxBalanceAtPcs = maxBalanceAtPcs,
            excessLeave = excessLeave,
            specialLeaveBalance = specialLeaveBalance,
            daysPerWeekToUse = daysPerWeek,
            daysPerMonthToUse = daysPerMonth,
            milestones = milestones,
            notes = notes
        )
    }

    /** Legacy wrapper — prefer [plan]. */
    fun planPcs(
        currentBalance: Double,
        pcsDateMillis: Long,
        maxBalanceAtPcs: Double = DEFAULT_MAX_BALANCE_AT_PCS,
        accrualPerMonth: Double = DEFAULT_ACCRUAL_PER_MONTH,
        maxAccruingBalance: Double = DEFAULT_MAX_ACCRUING_BALANCE,
        referenceMillis: Long = System.currentTimeMillis(),
        zoneId: ZoneId = ZoneId.systemDefault()
    ): LeavePcsPlanResult? {
        val full = plan(currentBalance, pcsDateMillis, maxBalanceAtPcs, referenceMillis = referenceMillis, zoneId = zoneId)
            ?: return null
        val projection = projectBalance(
            currentBalance, pcsDateMillis, accrualPerMonth, maxAccruingBalance, referenceMillis, zoneId
        )
        return LeavePcsPlanResult(
            pcsDateMillis = pcsDateMillis,
            projectedBalanceAtPcs = projection?.projectedBalance ?: currentBalance,
            maxBalanceAtPcs = maxBalanceAtPcs,
            overCapBy = full.excessLeave,
            recommendations = full.notes
        )
    }

    private fun daysUntilLeaveNeeded(
        currentBalance: Double,
        requestedDays: Double,
        accrualPerMonth: Double,
        maxBalance: Double
    ): Int? {
        if (currentBalance >= requestedDays || accrualPerMonth <= 0) return null
        val deficit = requestedDays - currentBalance
        val roomToCap = max(0.0, maxBalance - currentBalance)
        val achievableAccrual = min(deficit, roomToCap)
        val monthsNeeded = achievableAccrual / accrualPerMonth
        return ceil(monthsNeeded * DAYS_PER_ACCRUAL_MONTH).toInt()
    }

    private fun buildMilestones(
        excessLeave: Double,
        daysUntilPcs: Int,
        referenceDate: LocalDate,
        zoneId: ZoneId
    ): List<LeaveMilestone> {
        if (excessLeave <= 0) return emptyList()
        val checkpointCount = min(4, max(1, daysUntilPcs / 30))
        val intervalDays = max(7, daysUntilPcs / checkpointCount)
        return (1..checkpointCount).mapNotNull { index ->
            val checkpointDate = referenceDate.plusDays((intervalDays * index).toLong())
            val progress = index.toDouble() / checkpointCount.toDouble()
            val cumulativeTarget = (excessLeave * progress).roundToInt().toDouble()
            LeaveMilestone(
                dateMillis = toMillis(checkpointDate, zoneId),
                title = "Use ${formattedDays(cumulativeTarget)} by then",
                detail = "${(progress * 100).roundToInt()}% of excess leave planned"
            )
        }
    }

    private fun nextFiscalYearEnd(afterDate: LocalDate): LocalDate? {
        var year = afterDate.year
        var candidate = LocalDate.of(year, 9, 30)
        if (!candidate.isAfter(afterDate)) {
            year += 1
            candidate = LocalDate.of(year, 9, 30)
        }
        return candidate
    }

    private fun formattedDays(value: Double): String {
        val rounded = (value * 10).roundToInt() / 10.0
        return if (rounded == rounded.roundToInt().toDouble()) {
            "${rounded.roundToInt()} days"
        } else {
            "%.1f days".format(rounded)
        }
    }

    private fun formattedRate(value: Double): String =
        if (value == value.roundToInt().toDouble()) {
            "${value.roundToInt()} days/month"
        } else {
            "%.1f days/month".format(value)
        }

    private fun formatDate(date: LocalDate): String = dateFormat.format(date)

    private fun toLocalDate(millis: Long, zoneId: ZoneId): LocalDate =
        LeaveDateUtils.toLocalDate(millis, zoneId)

    private fun toMillis(date: LocalDate, zoneId: ZoneId): Long =
        LeaveDateUtils.toStartOfDayMillis(date, zoneId)
}
