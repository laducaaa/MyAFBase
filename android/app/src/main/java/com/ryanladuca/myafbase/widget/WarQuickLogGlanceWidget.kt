package com.ryanladuca.myafbase.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.height
import androidx.compose.ui.unit.dp

class WarQuickLogGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = loadWidgetStore(context)?.loadWarTracker()
        val useDynamic = useDynamicColors()
        val clickAction = actionStartActivity(WidgetActions.openWarQuickLog(context))
        provideContent {
            if (useDynamic) GlanceTheme { WarQuickLogWidgetContent(snapshot, useDynamic, clickAction) }
            else WarQuickLogWidgetContent(snapshot, useDynamic, clickAction)
        }
    }
}

@Composable
private fun WarQuickLogWidgetContent(
    snapshot: WarWidgetSnapshot?,
    useDynamic: Boolean,
    clickAction: androidx.glance.action.Action,
) {
    WidgetSurface(useDynamic = useDynamic) {
        Column(modifier = GlanceModifier.clickable(clickAction)) {
            WidgetTitle("WAR Tracker", useDynamic)
            Spacer(modifier = GlanceModifier.height(4.dp))
            val count = snapshot?.entriesThisWeek ?: 0
            WidgetAccent("$count this week", useDynamic)
            WidgetSubtitle(snapshot?.weekRangeLabel ?: "Tap to log", useDynamic)
        }
    }
}

class WarQuickLogGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = WarQuickLogGlanceWidget()
}
