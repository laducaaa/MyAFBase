package com.ryanladuca.myafbase.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.ryanladuca.myafbase.R

class NotificationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        NotificationChannels.ensureAll(context)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: return
        val body = intent.getStringExtra(EXTRA_BODY) ?: return
        val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID) ?: NotificationChannels.READINESS
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, title.hashCode())
        val targetTab = intent.getStringExtra(NotificationIntents.EXTRA_TARGET_TAB)
        val targetTool = intent.getStringExtra(NotificationIntents.EXTRA_TARGET_TOOL)
        val repeatAction = intent.getStringExtra(EXTRA_REPEAT_ACTION)

        val contentIntent = NotificationIntents.contentPendingIntent(
            context = context,
            requestCode = notificationId,
            targetTab = targetTab,
            targetTool = targetTool,
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .build()

        if (NotificationManagerCompat.from(context).areNotificationsEnabled()) {
            NotificationManagerCompat.from(context).notify(notificationId, notification)
        }

        when (repeatAction) {
            REPEAT_DAILY -> {
                val hour = intent.getIntExtra(EXTRA_REPEAT_HOUR, 20)
                WarNotificationScheduler.scheduleDailyNudge(context, hour)
            }
            REPEAT_WEEKLY -> {
                val weekday = intent.getIntExtra(EXTRA_REPEAT_WEEKDAY, 6)
                val hour = intent.getIntExtra(EXTRA_REPEAT_HOUR, 15)
                WarNotificationScheduler.scheduleWeeklyReminder(context, weekday, hour)
            }
        }
    }

    companion object {
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_CHANNEL_ID = "channel_id"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_REPEAT_ACTION = "repeat_action"
        const val EXTRA_REPEAT_HOUR = "repeat_hour"
        const val EXTRA_REPEAT_WEEKDAY = "repeat_weekday"
        const val REPEAT_DAILY = "daily"
        const val REPEAT_WEEKLY = "weekly"
    }
}
