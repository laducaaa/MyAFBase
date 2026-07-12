package com.ryanladuca.myafbase.domain.logic

import java.util.Calendar

enum class PayEventKind(val title: String, val subtitle: String) {
    MID_MONTH("Mid-month pay", "Typically the 15th"),
    MONTH_END("Month-end pay", "Typically the 1st")
}

data class PayCalendarEvent(
    val id: String,
    val kind: PayEventKind,
    val dateMillis: Long,
    val isSpecial: Boolean = false,
    val specialTitle: String? = null
) {
    val title: String get() = if (isSpecial && specialTitle != null) specialTitle else kind.title
}

data class SpecialPayEntry(
    val id: String,
    val title: String,
    val dateMillis: Long,
    val notes: String? = null
)

enum class PayInsightSeverity { Warning, Info }

data class PayCalendarInsight(
    val severity: PayInsightSeverity,
    val title: String,
    val message: String,
    val gapDays: Int? = null,
    val featured: Boolean = false,
)

object PayCalendar {
    fun upcomingEvents(
        fromMillis: Long = System.currentTimeMillis(),
        monthsAhead: Int = 14,
        specialPays: List<SpecialPayEntry> = emptyList()
    ): List<PayCalendarEvent> {
        val cal = Calendar.getInstance()
        cal.timeInMillis = fromMillis
        startOfDay(cal)
        val today = cal.timeInMillis

        val endCal = Calendar.getInstance().apply {
            timeInMillis = today
            add(Calendar.MONTH, monthsAhead)
        }
        val rangeEnd = endCal.timeInMillis

        val events = mutableListOf<PayCalendarEvent>()
        val cursor = Calendar.getInstance().apply {
            timeInMillis = today
            set(Calendar.DAY_OF_MONTH, 1)
            startOfDay(this)
        }

        while (cursor.timeInMillis <= rangeEnd) {
            for (kind in PayEventKind.entries) {
                val pay = payDate(kind, cursor) ?: continue
                if (pay >= today) {
                    events += PayCalendarEvent(
                        id = "${kind.name}-$pay",
                        kind = kind,
                        dateMillis = pay
                    )
                }
            }
            cursor.add(Calendar.MONTH, 1)
        }

        for (special in specialPays) {
            val pay = startOfDayMillis(special.dateMillis)
            if (pay in today..rangeEnd) {
                events += PayCalendarEvent(
                    id = "special-${special.id}",
                    kind = PayEventKind.MID_MONTH,
                    dateMillis = pay,
                    isSpecial = true,
                    specialTitle = special.title
                )
            }
        }

        return events.sortedBy { it.dateMillis }
    }

    fun daysUntil(dateMillis: Long, fromMillis: Long = System.currentTimeMillis()): Int {
        val start = startOfDayMillis(fromMillis)
        val target = startOfDayMillis(dateMillis)
        return ((target - start) / (24 * 60 * 60 * 1000L)).toInt()
    }

    fun gapDays(earlier: Long, later: Long): Int = daysUntil(later, earlier)

    data class PayGapInsight(
        val prior: PayCalendarEvent,
        val next: PayCalendarEvent,
        val gapDays: Int
    ) {
        val isLongGap: Boolean get() = gapDays > 14
        val isShortGap: Boolean get() = gapDays < 10
    }

    fun payGaps(events: List<PayCalendarEvent>): List<PayGapInsight> {
        val sorted = events.sortedBy { it.dateMillis }
        if (sorted.size < 2) return emptyList()
        return sorted.zipWithNext { prior, next ->
            PayGapInsight(prior, next, gapDays(prior.dateMillis, next.dateMillis))
        }
    }

    fun longGapInsights(events: List<PayCalendarEvent>): List<PayGapInsight> =
        payGaps(events).filter { it.isLongGap }

    fun insights(events: List<PayCalendarEvent>): List<PayCalendarInsight> {
        val gaps = payGaps(events)
        val notes = mutableListOf<PayCalendarInsight>()
        gaps.filter { it.isLongGap }.forEach {
            notes += PayCalendarInsight(
                severity = PayInsightSeverity.Warning,
                title = "Long pay gap",
                message = "${it.gapDays} days between ${it.prior.title} and ${it.next.title}.",
                gapDays = it.gapDays,
                featured = true,
            )
        }
        gaps.filter { it.isShortGap }.take(2).forEach {
            notes += PayCalendarInsight(
                severity = PayInsightSeverity.Info,
                title = "Clustered pays",
                message = "${it.gapDays} days: ${it.prior.title} → ${it.next.title}.",
            )
        }
        if (notes.isEmpty()) {
            notes += PayCalendarInsight(
                severity = PayInsightSeverity.Info,
                title = "Typical spacing",
                message = "Upcoming pay spacing looks typical.",
            )
        }
        return notes
    }

    fun insightSummary(insights: List<PayCalendarInsight>): String {
        val warnings = insights.count { it.severity == PayInsightSeverity.Warning }
        val featured = insights.firstOrNull { it.featured }
        return when {
            featured != null -> "${featured.gapDays} day gap · $warnings warning${if (warnings == 1) "" else "s"}"
            warnings > 0 -> "$warnings insight${if (warnings == 1) "" else "s"}"
            else -> insights.firstOrNull()?.message ?: "Tap to expand"
        }
    }

    fun insightsLegacy(events: List<PayCalendarEvent>): List<String> =
        insights(events).map { "${it.title}: ${it.message}" }

    private fun payDate(kind: PayEventKind, month: Calendar): Long? {
        val year = month.get(Calendar.YEAR)
        val monthValue = month.get(Calendar.MONTH)
        val cal = Calendar.getInstance()
        when (kind) {
            PayEventKind.MID_MONTH -> {
                cal.set(year, monthValue, 15)
            }
            PayEventKind.MONTH_END -> {
                cal.set(year, monthValue, 1)
            }
        }
        startOfDay(cal)
        return adjustedPayday(cal.timeInMillis)
    }

    fun adjustedPayday(dateMillis: Long): Long {
        val cal = Calendar.getInstance().apply { timeInMillis = dateMillis }
        startOfDay(cal)
        return when (cal.get(Calendar.DAY_OF_WEEK)) {
            Calendar.SUNDAY -> {
                cal.add(Calendar.DAY_OF_MONTH, -2)
                cal.timeInMillis
            }
            Calendar.SATURDAY -> {
                cal.add(Calendar.DAY_OF_MONTH, -1)
                cal.timeInMillis
            }
            else -> cal.timeInMillis
        }
    }

    private fun startOfDay(cal: Calendar) {
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
    }

    private fun startOfDayMillis(millis: Long): Long {
        val cal = Calendar.getInstance().apply { timeInMillis = millis }
        startOfDay(cal)
        return cal.timeInMillis
    }
}
