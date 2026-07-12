package com.ryanladuca.myafbase.domain.logic

import java.util.Calendar
import java.util.Locale

enum class OpenStatus { OPEN, CLOSED, ALWAYS_OPEN }

data class ParsedHours(
    val status: OpenStatus? = null,
    val todayHoursText: String? = null,
    val fallbackText: String? = null,
    val isStructured: Boolean = false
)

object HoursParser {
    private val dayAliases = mapOf(
        "sun" to Calendar.SUNDAY, "sunday" to Calendar.SUNDAY,
        "mon" to Calendar.MONDAY, "monday" to Calendar.MONDAY,
        "tue" to Calendar.TUESDAY, "tues" to Calendar.TUESDAY, "tuesday" to Calendar.TUESDAY,
        "wed" to Calendar.WEDNESDAY, "wednesday" to Calendar.WEDNESDAY,
        "thu" to Calendar.THURSDAY, "thur" to Calendar.THURSDAY, "thursday" to Calendar.THURSDAY,
        "fri" to Calendar.FRIDAY, "friday" to Calendar.FRIDAY,
        "sat" to Calendar.SATURDAY, "saturday" to Calendar.SATURDAY
    )

    fun parse(raw: String, nowMillis: Long = System.currentTimeMillis()): ParsedHours {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return ParsedHours(fallbackText = null)

        val lower = trimmed.lowercase(Locale.US)
        when {
            lower.contains("24/7") || lower.contains("24 hours") ||
                lower.contains("always open") || lower == "open" -> {
                return ParsedHours(
                    status = OpenStatus.ALWAYS_OPEN,
                    todayHoursText = "Open 24/7",
                    fallbackText = trimmed,
                    isStructured = true
                )
            }
            lower == "closed" || lower.startsWith("closed ") -> {
                return ParsedHours(
                    status = OpenStatus.CLOSED,
                    todayHoursText = "Closed",
                    fallbackText = trimmed,
                    isStructured = true
                )
            }
        }

        val cal = Calendar.getInstance().apply { timeInMillis = nowMillis }
        val today = cal.get(Calendar.DAY_OF_WEEK)
        val rangeMatch = Regex(
            """(?i)(mon|tue|tues|wed|thu|thur|fri|sat|sun)[a-z]*\s*[-–to]+\s*(mon|tue|tues|wed|thu|thur|fri|sat|sun)[a-z]*\s+(\d{1,4}):?(\d{2})?\s*[-–]\s*(\d{1,4}):?(\d{2})?"""
        ).find(trimmed)

        if (rangeMatch != null) {
            val startDay = dayAliases[rangeMatch.groupValues[1].lowercase(Locale.US)]
            val endDay = dayAliases[rangeMatch.groupValues[2].lowercase(Locale.US)]
            val openMin = toMinutes(rangeMatch.groupValues[3], rangeMatch.groupValues[4])
            val closeMin = toMinutes(rangeMatch.groupValues[5], rangeMatch.groupValues[6])
            if (startDay != null && endDay != null && openMin != null && closeMin != null) {
                val inDayRange = dayInRange(today, startDay, endDay)
                val nowMin = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
                val openNow = inDayRange && nowMin in openMin until closeMin
                return ParsedHours(
                    status = if (openNow) OpenStatus.OPEN else OpenStatus.CLOSED,
                    todayHoursText = if (inDayRange) formatRange(openMin, closeMin) else "Closed today",
                    fallbackText = trimmed,
                    isStructured = true
                )
            }
        }

        return ParsedHours(fallbackText = trimmed, todayHoursText = trimmed)
    }

    fun isOpenNow(hours: String?, nowMillis: Long = System.currentTimeMillis()): Boolean? {
        if (hours.isNullOrBlank()) return null
        return when (parse(hours, nowMillis).status) {
            OpenStatus.ALWAYS_OPEN, OpenStatus.OPEN -> true
            OpenStatus.CLOSED -> false
            null -> null
        }
    }

    fun cardDisplay(raw: String, nowMillis: Long = System.currentTimeMillis()): String {
        val parsed = parse(raw, nowMillis)
        return parsed.todayHoursText ?: parsed.fallbackText ?: raw
    }

    private fun toMinutes(hourPart: String, minutePart: String): Int? {
        val h = hourPart.toIntOrNull() ?: return null
        val m = if (minutePart.isBlank()) {
            if (h >= 100) h % 100 else 0
        } else {
            minutePart.toIntOrNull() ?: 0
        }
        val hour = if (minutePart.isBlank() && h >= 100) h / 100 else h
        if (hour !in 0..23 || m !in 0..59) return null
        return hour * 60 + m
    }

    private fun formatRange(openMin: Int, closeMin: Int): String {
        fun fmt(min: Int) = "%02d%02d".format(min / 60, min % 60)
        return "${fmt(openMin)}–${fmt(closeMin)}"
    }

    private fun dayInRange(today: Int, start: Int, end: Int): Boolean {
        return if (start <= end) today in start..end else today >= start || today <= end
    }
}
