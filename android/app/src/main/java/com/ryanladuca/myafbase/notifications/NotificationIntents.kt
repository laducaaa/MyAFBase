package com.ryanladuca.myafbase.notifications

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.ryanladuca.myafbase.MainActivity

object NotificationIntents {
    const val EXTRA_TARGET_TAB = "target_tab"
    const val EXTRA_TARGET_TOOL = "target_tool"
    const val EXTRA_SHOW_EMERGENCY = "show_emergency"
    const val EXTRA_WAR_QUICK_LOG = "war_quick_log"
    const val EXTRA_WAR_QUICK_LOG_TEXT = "war_quick_log_text"
    const val TAB_HOME = "home"
    const val TAB_EXPLORE = "explore"
    const val TAB_REMINDERS = "reminders"
    const val TAB_ASSIGNMENT = "assignment"
    const val TOOL_WAR_TRACKER = "war-tracker"

    fun contentPendingIntent(
        context: Context,
        requestCode: Int,
        targetTab: String? = null,
        targetTool: String? = null,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            targetTab?.let { putExtra(EXTRA_TARGET_TAB, it) }
            targetTool?.let { putExtra(EXTRA_TARGET_TOOL, it) }
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
