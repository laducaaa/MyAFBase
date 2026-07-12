package com.ryanladuca.myafbase.domain.logic

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.WeekFields
import java.util.Locale

object WarDateMath {
    private val dayLabelFormat = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.US)

    fun startOfDay(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate()
        return date.atStartOfDay(zoneId).toInstant().toEpochMilli()
    }

    fun startOfWeek(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate()
        val weekFields = WeekFields.of(Locale.getDefault())
        val start = date.with(weekFields.dayOfWeek(), 1L)
        return start.atStartOfDay(zoneId).toInstant().toEpochMilli()
    }

    fun addDays(millis: Long, days: Int, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate().plusDays(days.toLong())
        return date.atStartOfDay(zoneId).toInstant().toEpochMilli()
    }

    fun dayLabel(millis: Long, zoneId: ZoneId = ZoneId.systemDefault(), todayMillis: Long = System.currentTimeMillis()): String {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate()
        val today = Instant.ofEpochMilli(todayMillis).atZone(zoneId).toLocalDate()
        return if (date == today) "Today" else dayLabelFormat.format(date)
    }

    fun isSameDay(aMillis: Long, bMillis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Boolean {
        val zone = zoneId
        val a = Instant.ofEpochMilli(aMillis).atZone(zone).toLocalDate()
        val b = Instant.ofEpochMilli(bMillis).atZone(zone).toLocalDate()
        return a == b
    }

    fun weekDays(weekStartMillis: Long): List<Long> =
        (0..6).map { day -> weekStartMillis + day * 86_400_000L }

    fun endOfDay(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate()
        return date.atTime(23, 59, 59).atZone(zoneId).toInstant().toEpochMilli()
    }

    fun startOfMonth(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate().withDayOfMonth(1)
        return date.atStartOfDay(zoneId).toInstant().toEpochMilli()
    }

    fun endOfMonth(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate()
        val lastDay = date.lengthOfMonth()
        return date.withDayOfMonth(lastDay).atTime(23, 59, 59).atZone(zoneId).toInstant().toEpochMilli()
    }

    fun startOfQuarter(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate()
        val quarterMonth = ((date.monthValue - 1) / 3) * 3 + 1
        return date.withMonth(quarterMonth).withDayOfMonth(1).atStartOfDay(zoneId).toInstant().toEpochMilli()
    }

    fun endOfQuarter(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val start = Instant.ofEpochMilli(startOfQuarter(millis, zoneId)).atZone(zoneId).toLocalDate()
        val endMonth = start.monthValue + 2
        val endDate = start.withMonth(endMonth).withDayOfMonth(start.withMonth(endMonth).lengthOfMonth())
        return endDate.atTime(23, 59, 59).atZone(zoneId).toInstant().toEpochMilli()
    }

    fun startOfYear(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate().withDayOfYear(1)
        return date.atStartOfDay(zoneId).toInstant().toEpochMilli()
    }

    fun endOfYear(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate().withDayOfYear(
            Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate().lengthOfYear()
        )
        return date.atTime(23, 59, 59).atZone(zoneId).toInstant().toEpochMilli()
    }

    fun addYears(millis: Long, years: Int, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate().plusYears(years.toLong())
        return date.atStartOfDay(zoneId).toInstant().toEpochMilli()
    }

    fun rangeLabel(fromMillis: Long, toMillis: Long, zoneId: ZoneId = ZoneId.systemDefault()): String {
        val fmt = DateTimeFormatter.ofPattern("MMM d", Locale.US)
        val from = Instant.ofEpochMilli(fromMillis).atZone(zoneId).toLocalDate()
        val to = Instant.ofEpochMilli(toMillis).atZone(zoneId).toLocalDate()
        return "${fmt.format(from)} – ${fmt.format(to)}"
    }
}
