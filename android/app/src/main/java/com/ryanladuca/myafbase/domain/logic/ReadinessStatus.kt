package com.ryanladuca.myafbase.domain.logic

import java.util.concurrent.TimeUnit

enum class ReadinessStatus(val label: String) {
    NOT_SET("Not set"),
    ON_TRACK("On track"),
    DUE_SOON("Due soon"),
    OVERDUE("Overdue"),
    WINDOW_OPEN("Window open");

    companion object {
        fun evaluate(dueMillis: Long?, referenceMillis: Long = System.currentTimeMillis()): ReadinessStatus {
            if (dueMillis == null) return NOT_SET
            val days = TimeUnit.MILLISECONDS.toDays(startOfDay(dueMillis) - startOfDay(referenceMillis)).toInt()
            return when {
                days < 0 -> OVERDUE
                days <= 30 -> DUE_SOON
                else -> ON_TRACK
            }
        }

        fun evaluatePcsWindow(startMillis: Long?, endMillis: Long?, referenceMillis: Long = System.currentTimeMillis()): ReadinessStatus {
            if (startMillis == null || endMillis == null) return NOT_SET
            val now = startOfDay(referenceMillis)
            val start = startOfDay(startMillis)
            val end = startOfDay(endMillis)
            return if (now in start..end) WINDOW_OPEN else evaluate(endMillis, referenceMillis)
        }

        private fun startOfDay(millis: Long): Long {
            val cal = java.util.Calendar.getInstance().apply { timeInMillis = millis }
            cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
            cal.set(java.util.Calendar.MINUTE, 0)
            cal.set(java.util.Calendar.SECOND, 0)
            cal.set(java.util.Calendar.MILLISECOND, 0)
            return cal.timeInMillis
        }
    }
}
