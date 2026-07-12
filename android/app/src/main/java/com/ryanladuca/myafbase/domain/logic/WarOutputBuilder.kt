package com.ryanladuca.myafbase.domain.logic

import com.ryanladuca.myafbase.data.db.WarEntryEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class WarDateRangePreset(val title: String) {
    THIS_WEEK("This Week"),
    THIS_MONTH("This Month"),
    THIS_QUARTER("This Quarter"),
    THIS_YEAR("This Year"),
    CLOSEOUT_CYCLE("EPB/OPB Cycle"),
    CUSTOM("Custom"),
}

enum class WarOutputGrouping(val title: String) {
    CHRONOLOGICAL("Chronological"),
    CATEGORY("By Category"),
    PERFORMANCE_FACTOR("By Factor"),
}

enum class WarOutputFormat(val title: String, val helpText: String) {
    PLAIN_TEXT(
        "Plain Text",
        "Full detail per entry — good for email or a narrative summary.",
    ),
    DRAFT_BULLETS(
        "Draft Bullets",
        "One condensed line per entry — a starting point for award or eval bullets.",
    ),
}

enum class WarMemberType(val title: String, val reportAbbreviation: String) {
    ENLISTED("Enlisted", "EPB"),
    OFFICER("Officer", "OPB"),
}

data class WarOutputSummary(
    val totalEntries: Int,
    val totalHours: Double,
    val categoryCounts: List<Pair<String, Int>>,
) {
    companion object {
        val EMPTY = WarOutputSummary(0, 0.0, emptyList())
    }
}

object WarOutputBuilder {
    private val dateLabelFormat = SimpleDateFormat("MMM d", Locale.US)

    fun dateRange(
        preset: WarDateRangePreset,
        nowMillis: Long = System.currentTimeMillis(),
        customStartMillis: Long = nowMillis,
        customEndMillis: Long = nowMillis,
        evalCloseoutMillis: Long? = null,
    ): LongRange {
        return when (preset) {
            WarDateRangePreset.THIS_WEEK -> {
                val start = WarDateMath.startOfWeek(nowMillis)
                val end = WarDateMath.endOfDay(WarDateMath.addDays(start, 6))
                start..end
            }
            WarDateRangePreset.THIS_MONTH -> {
                val start = WarDateMath.startOfMonth(nowMillis)
                val end = WarDateMath.endOfMonth(nowMillis)
                start..end
            }
            WarDateRangePreset.THIS_QUARTER -> {
                val start = WarDateMath.startOfQuarter(nowMillis)
                val end = WarDateMath.endOfQuarter(nowMillis)
                start..end
            }
            WarDateRangePreset.THIS_YEAR -> {
                val start = WarDateMath.startOfYear(nowMillis)
                val end = WarDateMath.endOfYear(nowMillis)
                start..end
            }
            WarDateRangePreset.CLOSEOUT_CYCLE -> {
                if (evalCloseoutMillis == null) {
                    val start = WarDateMath.startOfYear(nowMillis)
                    val end = WarDateMath.endOfYear(nowMillis)
                    start..end
                } else {
                    val start = WarDateMath.addYears(evalCloseoutMillis, -1)
                    val end = maxOf(evalCloseoutMillis, nowMillis)
                    minOf(start, end)..end
                }
            }
            WarDateRangePreset.CUSTOM -> {
                val start = WarDateMath.startOfDay(minOf(customStartMillis, customEndMillis))
                val end = WarDateMath.endOfDay(maxOf(customStartMillis, customEndMillis))
                start..end
            }
        }
    }

    fun entriesInRange(entries: List<WarEntryEntity>, range: LongRange): List<WarEntryEntity> =
        entries.filter { it.dateMillis in range }

    fun summary(entries: List<WarEntryEntity>): WarOutputSummary {
        if (entries.isEmpty()) return WarOutputSummary.EMPTY
        val totalHours = entries.sumOf { it.hours }
        val categoryCounts = entries.groupingBy { it.category }.eachCount()
            .entries
            .sortedByDescending { it.value }
            .map { it.key to it.value }
        return WarOutputSummary(entries.size, totalHours, categoryCounts)
    }

    fun build(
        entries: List<WarEntryEntity>,
        grouping: WarOutputGrouping,
        format: WarOutputFormat,
    ): String {
        if (entries.isEmpty()) return "No entries in this date range yet."
        val sorted = entries.sortedBy { it.dateMillis }
        return when (grouping) {
            WarOutputGrouping.CHRONOLOGICAL -> sorted.joinToString("\n\n") { lineFor(it, format) }
            WarOutputGrouping.CATEGORY -> groupedBlocks(sorted, format) { it.category }
            WarOutputGrouping.PERFORMANCE_FACTOR -> groupedBlocks(sorted, format) { it.tags.ifBlank { "Unmapped" } }
        }
    }

    private fun groupedBlocks(
        entries: List<WarEntryEntity>,
        format: WarOutputFormat,
        keyFor: (WarEntryEntity) -> String,
    ): String {
        val order = mutableListOf<String>()
        val groups = linkedMapOf<String, MutableList<WarEntryEntity>>()
        entries.forEach { entry ->
            val key = keyFor(entry)
            if (!groups.containsKey(key)) order.add(key)
            groups.getOrPut(key) { mutableListOf() }.add(entry)
        }
        return order.joinToString("\n\n\n") { key ->
            val header = key.uppercase(Locale.US)
            val body = groups[key].orEmpty().joinToString("\n\n") { lineFor(it, format) }
            "$header\n$body"
        }
    }

    private fun lineFor(entry: WarEntryEntity, format: WarOutputFormat): String =
        when (format) {
            WarOutputFormat.PLAIN_TEXT -> plainTextBlock(entry)
            WarOutputFormat.DRAFT_BULLETS -> bulletLine(entry)
        }

    private fun plainTextBlock(entry: WarEntryEntity): String = buildString {
        append("${dateLabel(entry.dateMillis)} — ${entry.category}")
        append('\n')
        append(entry.body)
        if (entry.impact.isNotBlank()) {
            append('\n')
            append("Impact: ${entry.impact}")
        }
        if (entry.hours > 0) {
            append('\n')
            append("Hours: ${hoursLabel(entry.hours)}")
        }
        if (entry.tags.isNotBlank()) {
            append('\n')
            append(entry.tags.split(',').joinToString(" ") { "#${it.trim()}" })
        }
    }

    private fun bulletLine(entry: WarEntryEntity): String {
        var text = entry.body.trim()
        if (entry.impact.isNotBlank()) text += "; ${entry.impact.trim()}"
        if (entry.hours > 0) text += " (${hoursLabel(entry.hours)})"
        return "- ${dateLabel(entry.dateMillis)}: $text"
    }

    private fun dateLabel(millis: Long): String = dateLabelFormat.format(Date(millis))

    private fun hoursLabel(hours: Double): String =
        if (hours == hours.toInt().toDouble()) "${hours.toInt()}h" else String.format(Locale.US, "%.1fh", hours)
}

object WarRetentionService {
    suspend fun purgeExpiredEntries(
        entries: List<WarEntryEntity>,
        autoDeleteEnabled: Boolean,
        autoDeleteAfterYears: Int,
        delete: suspend (String) -> Unit,
    ) {
        if (!autoDeleteEnabled) return
        val cutoff = WarDateMath.addYears(System.currentTimeMillis(), -autoDeleteAfterYears)
        entries.filter { it.dateMillis < cutoff }.forEach { delete(it.id) }
    }
}
