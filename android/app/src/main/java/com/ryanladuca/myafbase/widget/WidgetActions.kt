package com.ryanladuca.myafbase.widget

import android.content.Context
import android.content.Intent
import com.ryanladuca.myafbase.MainActivity
import com.ryanladuca.myafbase.domain.model.HomeToolId
import com.ryanladuca.myafbase.notifications.NotificationIntents

object WidgetActions {
    fun openHome(context: Context, showEmergency: Boolean = false): Intent =
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(NotificationIntents.EXTRA_TARGET_TAB, NotificationIntents.TAB_HOME)
            if (showEmergency) putExtra(NotificationIntents.EXTRA_SHOW_EMERGENCY, true)
        }

    fun openExplore(context: Context): Intent =
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(NotificationIntents.EXTRA_TARGET_TAB, NotificationIntents.TAB_EXPLORE)
        }

    fun openAssignment(context: Context): Intent =
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(NotificationIntents.EXTRA_TARGET_TAB, NotificationIntents.TAB_ASSIGNMENT)
        }

    fun openTool(context: Context, toolId: String): Intent =
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(NotificationIntents.EXTRA_TARGET_TOOL, toolId)
        }

    fun openWarQuickLog(context: Context, prefill: String? = null): Intent =
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(NotificationIntents.EXTRA_WAR_QUICK_LOG, true)
            prefill?.let { putExtra(NotificationIntents.EXTRA_WAR_QUICK_LOG_TEXT, it) }
        }

    fun dialNumber(context: Context, number: String): Intent =
        Intent(Intent.ACTION_DIAL).apply {
            data = android.net.Uri.parse("tel:$number")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
}

object WidgetToolIds {
    val PAY = HomeToolId.PAY_CALENDAR.id
}
