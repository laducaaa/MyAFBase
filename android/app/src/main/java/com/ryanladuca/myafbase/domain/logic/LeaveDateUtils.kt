package com.ryanladuca.myafbase.domain.logic

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset

object LeaveDateUtils {
    fun toLocalDate(millis: Long, zoneId: ZoneId = ZoneId.systemDefault()): LocalDate =
        Instant.ofEpochMilli(millis).atZone(zoneId).toLocalDate()

    fun toStartOfDayMillis(date: LocalDate, zoneId: ZoneId = ZoneId.systemDefault()): Long =
        date.atStartOfDay(zoneId).toInstant().toEpochMilli()

    fun localDate(year: Int, month: Int, day: Int): LocalDate = LocalDate.of(year, month, day)

    /** DatePicker returns UTC midnight for the selected calendar day. */
    fun fromDatePickerMillis(pickerMillis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(pickerMillis).atZone(ZoneOffset.UTC).toLocalDate()
        return toStartOfDayMillis(date, zoneId)
    }

    fun toDatePickerMillis(storedMillis: Long, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val date = toLocalDate(storedMillis, zoneId)
        return date.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
    }
}
