package com.ryanladuca.myafbase.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.ryanladuca.myafbase.data.db.ReadinessEntity
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId

object ReadinessNotificationScheduler {
    private const val PREFIX = "readiness"
    private val reminderOffsets = listOf(14, 7, 1)
    private const val notificationHour = 9

    data class DueItem(val id: String, val title: String, val dueMillis: Long?)

    fun reschedule(
        context: Context,
        baseId: String,
        baseName: String,
        readiness: ReadinessEntity?,
        enabled: Boolean,
    ) {
        cancelForBase(context, baseId)
        if (!enabled || readiness == null || !NotificationPermission.isGranted(context)) return

        val items = listOf(
            DueItem("fitness", "Fitness test due", readiness.fitnessTestDueMillis),
            DueItem("dental", "Annual dental due", readiness.dentalDueMillis),
            DueItem("eval", "EPR / OPB closeout", readiness.evalCloseoutDueMillis),
            DueItem("cac", "CAC expiration", readiness.cacExpirationMillis),
            DueItem("clearance", "Clearance renewal", readiness.clearanceRenewalMillis),
            DueItem("pcs-window-start", "PCS window opens", readiness.pcsWindowStartMillis),
            DueItem("pcs-window-end", "PCS window closes", readiness.pcsWindowEndMillis),
        )

        items.forEach { item ->
            item.dueMillis?.let { due ->
                scheduleDueDateReminders(context, baseId, item.id, item.title, due, baseName)
            }
        }
    }

    fun cancelForBase(context: Context, baseId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        pendingRequestCodes(baseId).forEach { requestCode ->
            alarmManager.cancel(buildAlarmPendingIntent(context, requestCode))
        }
    }

    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        ReadinessRequestCodes.all().forEach { code ->
            alarmManager.cancel(buildAlarmPendingIntent(context, code))
        }
        ReadinessRequestCodes.clear()
    }

    private fun scheduleDueDateReminders(
        context: Context,
        baseId: String,
        itemId: String,
        title: String,
        dueMillis: Long,
        baseName: String,
    ) {
        val zone = ZoneId.systemDefault()
        val dueDate = Instant.ofEpochMilli(dueMillis).atZone(zone).toLocalDate()

        reminderOffsets.forEach { offset ->
            val reminderDay = dueDate.minusDays(offset.toLong())
            val fireAt = reminderDay.atTime(notificationHour, 0).atZone(zone).toInstant().toEpochMilli()
            if (fireAt > System.currentTimeMillis()) {
                val body = if (offset == 1) {
                    "Due tomorrow while assigned to $baseName."
                } else {
                    "Due in $offset days while assigned to $baseName."
                }
                scheduleAlarm(
                    context = context,
                    requestCode = ReadinessRequestCodes.code(baseId, itemId, offset),
                    title = title,
                    body = body,
                    fireAtMillis = fireAt,
                )
            }
        }

        val dueFireAt = dueDate.atTime(notificationHour, 0).atZone(zone).toInstant().toEpochMilli()
        if (dueFireAt > System.currentTimeMillis()) {
            scheduleAlarm(
                context = context,
                requestCode = ReadinessRequestCodes.code(baseId, itemId, 0),
                title = title,
                body = "Due today while assigned to $baseName.",
                fireAtMillis = dueFireAt,
            )
        }
    }

    private fun scheduleAlarm(
        context: Context,
        requestCode: Int,
        title: String,
        body: String,
        fireAtMillis: Long,
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, NotificationAlarmReceiver::class.java).apply {
            putExtra(NotificationAlarmReceiver.EXTRA_TITLE, title)
            putExtra(NotificationAlarmReceiver.EXTRA_BODY, body)
            putExtra(NotificationAlarmReceiver.EXTRA_CHANNEL_ID, NotificationChannels.READINESS)
            putExtra(NotificationAlarmReceiver.EXTRA_NOTIFICATION_ID, requestCode)
            putExtra(NotificationIntents.EXTRA_TARGET_TAB, NotificationIntents.TAB_REMINDERS)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAtMillis, pending)
    }

    private fun buildAlarmPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, NotificationAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun pendingRequestCodes(baseId: String): List<Int> {
        val itemIds = listOf(
            "fitness", "dental", "eval", "cac", "clearance",
            "pcs-window-start", "pcs-window-end",
        )
        return buildList {
            itemIds.forEach { itemId ->
                reminderOffsets.forEach { offset -> add(ReadinessRequestCodes.code(baseId, itemId, offset)) }
                add(ReadinessRequestCodes.code(baseId, itemId, 0))
            }
        }
    }
}

private object ReadinessRequestCodes {
    private val registered = mutableSetOf<Int>()

    fun code(baseId: String, itemId: String, offset: Int): Int {
        val value = ("readiness.$baseId.$itemId.$offset").hashCode() and 0x7FFFFFFF
        registered.add(value)
        return value
    }

    fun all(): Set<Int> = registered.toSet()
    fun clear() = registered.clear()
}
