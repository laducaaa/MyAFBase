package com.ryanladuca.myafbase.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

object NotificationChannels {
    const val READINESS = "readiness_reminders"
    const val WAR = "war_reminders"

    fun ensureAll(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                READINESS,
                "Readiness reminders",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Alerts for upcoming fitness, dental, CAC, and readiness dates."
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(
                WAR,
                "WAR Tracker reminders",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Daily log nudges, weekly WAR reminders, and award deadlines."
            },
        )
    }
}
