package com.ryanladuca.myafbase.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.ryanladuca.myafbase.data.db.WarAwardDeadlineEntity
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters

object WarNotificationScheduler {
    private const val DAILY_REQUEST = 2_001_001
    private const val WEEKLY_REQUEST = 2_001_002
    private const val DEADLINE_PREFIX = "war.deadline"
    private val deadlineOffsets = listOf(7, 3, 1)
    private const val deadlineHour = 9

    fun scheduleDailyNudge(context: Context, hour: Int) {
        cancelDaily(context)
        if (!NotificationPermission.isGranted(context)) return
        val fireAt = nextDailyFireAt(hour) ?: return
        val intent = baseIntent(context, DAILY_REQUEST).apply {
            putExtra(NotificationAlarmReceiver.EXTRA_TITLE, "Log something today?")
            putExtra(
                NotificationAlarmReceiver.EXTRA_BODY,
                "Add a quick WAR Tracker entry before you forget what you worked on.",
            )
            putExtra(NotificationAlarmReceiver.EXTRA_CHANNEL_ID, NotificationChannels.WAR)
            putExtra(NotificationIntents.EXTRA_TARGET_TOOL, NotificationIntents.TOOL_WAR_TRACKER)
            putExtra(NotificationAlarmReceiver.EXTRA_REPEAT_ACTION, NotificationAlarmReceiver.REPEAT_DAILY)
            putExtra(NotificationAlarmReceiver.EXTRA_REPEAT_HOUR, hour)
        }
        scheduleExact(context, DAILY_REQUEST, intent, fireAt)
    }

    fun cancelDaily(context: Context) {
        cancelExact(context, DAILY_REQUEST)
    }

    fun scheduleWeeklyReminder(context: Context, weekday: Int, hour: Int) {
        cancelWeekly(context)
        if (!NotificationPermission.isGranted(context)) return
        val fireAt = nextWeeklyFireAt(weekday, hour) ?: return
        val intent = baseIntent(context, WEEKLY_REQUEST).apply {
            putExtra(NotificationAlarmReceiver.EXTRA_TITLE, "WAR due Friday")
            putExtra(
                NotificationAlarmReceiver.EXTRA_BODY,
                "Wrap up this week's accomplishments in WAR Tracker.",
            )
            putExtra(NotificationAlarmReceiver.EXTRA_CHANNEL_ID, NotificationChannels.WAR)
            putExtra(NotificationIntents.EXTRA_TARGET_TOOL, NotificationIntents.TOOL_WAR_TRACKER)
            putExtra(NotificationAlarmReceiver.EXTRA_REPEAT_ACTION, NotificationAlarmReceiver.REPEAT_WEEKLY)
            putExtra(NotificationAlarmReceiver.EXTRA_REPEAT_WEEKDAY, weekday)
            putExtra(NotificationAlarmReceiver.EXTRA_REPEAT_HOUR, hour)
        }
        scheduleExact(context, WEEKLY_REQUEST, intent, fireAt)
    }

    fun cancelWeekly(context: Context) {
        cancelExact(context, WEEKLY_REQUEST)
    }

    fun rescheduleDeadlineReminders(
        context: Context,
        deadlines: List<WarAwardDeadlineEntity>,
        baseName: String,
    ) {
        cancelDeadlines(context)
        if (!NotificationPermission.isGranted(context)) return
        deadlines.forEach { deadline ->
            scheduleDeadlineReminders(context, deadline, baseName)
        }
    }

    fun cancelDeadlines(context: Context) {
        DeadlineRequestCodes.all().forEach { cancelExact(context, it) }
        DeadlineRequestCodes.clear()
    }

    fun cancelAll(context: Context) {
        cancelDaily(context)
        cancelWeekly(context)
        cancelDeadlines(context)
    }

    private fun scheduleDeadlineReminders(
        context: Context,
        deadline: WarAwardDeadlineEntity,
        baseName: String,
    ) {
        val zone = ZoneId.systemDefault()
        val dueDate = Instant.ofEpochMilli(deadline.deadlineMillis).atZone(zone).toLocalDate()
        deadlineOffsets.forEach { offset ->
            val reminderDay = dueDate.minusDays(offset.toLong())
            val fireAt = reminderDay.atTime(deadlineHour, 0).atZone(zone).toInstant().toEpochMilli()
            if (fireAt > System.currentTimeMillis()) {
                val body = if (offset == 1) {
                    "Due tomorrow — $baseName."
                } else {
                    "Due in $offset days — $baseName."
                }
                val requestCode = DeadlineRequestCodes.code(deadline.id, offset)
                val intent = baseIntent(context, requestCode).apply {
                    putExtra(NotificationAlarmReceiver.EXTRA_TITLE, deadline.title)
                    putExtra(NotificationAlarmReceiver.EXTRA_BODY, body)
                    putExtra(NotificationAlarmReceiver.EXTRA_CHANNEL_ID, NotificationChannels.WAR)
                    putExtra(NotificationIntents.EXTRA_TARGET_TOOL, NotificationIntents.TOOL_WAR_TRACKER)
                }
                scheduleExact(context, requestCode, intent, fireAt)
            }
        }
    }

    private fun nextDailyFireAt(hour: Int): Long? {
        val zone = ZoneId.systemDefault()
        val now = LocalDateTime.now(zone)
        var candidate = now.withHour(hour).withMinute(0).withSecond(0).withNano(0)
        if (!candidate.isAfter(now)) candidate = candidate.plusDays(1)
        return candidate.atZone(zone).toInstant().toEpochMilli()
    }

    private fun nextWeeklyFireAt(calendarWeekday: Int, hour: Int): Long? {
        val zone = ZoneId.systemDefault()
        val dayOfWeek = if (calendarWeekday == 1) DayOfWeek.SUNDAY else DayOfWeek.of(calendarWeekday - 1)
        val now = LocalDateTime.now(zone)
        var date = LocalDate.now(zone).with(TemporalAdjusters.nextOrSame(dayOfWeek))
        var candidate = date.atTime(hour, 0)
        if (!candidate.isAfter(now)) {
            date = date.plusWeeks(1)
            candidate = date.atTime(hour, 0)
        }
        return candidate.atZone(zone).toInstant().toEpochMilli()
    }

    private fun baseIntent(context: Context, requestCode: Int): Intent =
        Intent(context, NotificationAlarmReceiver::class.java).apply {
            putExtra(NotificationAlarmReceiver.EXTRA_NOTIFICATION_ID, requestCode)
        }

    private fun scheduleExact(context: Context, requestCode: Int, intent: Intent, fireAtMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAtMillis, pending)
    }

    private fun cancelExact(context: Context, requestCode: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, NotificationAlarmReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pending)
    }
}

private object DeadlineRequestCodes {
    private val registered = mutableSetOf<Int>()

    fun code(deadlineId: String, offset: Int): Int {
        val value = "war.deadline.$deadlineId.$offset".hashCode() and 0x7FFFFFFF
        registered.add(value)
        return value
    }

    fun all(): Set<Int> = registered.toSet()
    fun clear() = registered.clear()
}
