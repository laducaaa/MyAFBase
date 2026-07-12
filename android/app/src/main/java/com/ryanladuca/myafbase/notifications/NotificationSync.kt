package com.ryanladuca.myafbase.notifications

import android.content.Context
import com.ryanladuca.myafbase.data.AppContainer
import kotlinx.coroutines.flow.first

object NotificationSync {
    suspend fun refreshAll(context: Context, container: AppContainer) {
        NotificationChannels.ensureAll(context)
        if (!NotificationPermission.isGranted(context)) return

        val prefs = container.preferences
        val baseId = prefs.selectedBaseId.first() ?: return
        val baseName = container.appState.currentBase.value?.name ?: "your base"
        val readiness = container.database.readinessDao().get(baseId)
        val remindersEnabled = prefs.remindersEnabled.first()

        ReadinessNotificationScheduler.reschedule(
            context = context,
            baseId = baseId,
            baseName = baseName,
            readiness = readiness,
            enabled = remindersEnabled,
        )

        val warPrefs = prefs.warNotificationSettings()
        if (warPrefs.dailyNudgeEnabled) {
            WarNotificationScheduler.scheduleDailyNudge(context, warPrefs.dailyNudgeHour)
        } else {
            WarNotificationScheduler.cancelDaily(context)
        }
        if (warPrefs.weeklyReminderEnabled) {
            WarNotificationScheduler.scheduleWeeklyReminder(
                context,
                warPrefs.weeklyReminderWeekday,
                warPrefs.weeklyReminderHour,
            )
        } else {
            WarNotificationScheduler.cancelWeekly(context)
        }

        val deadlines = container.database.warAwardDeadlineDao().observeForBase(baseId).first()
        WarNotificationScheduler.rescheduleDeadlineReminders(context, deadlines, baseName)
    }
}
