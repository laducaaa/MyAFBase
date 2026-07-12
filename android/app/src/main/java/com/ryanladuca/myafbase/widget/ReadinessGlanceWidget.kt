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

class ReadinessGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = loadWidgetStore(context)?.loadReadiness()
        val useDynamic = useDynamicColors()
        val clickAction = actionStartActivity(WidgetActions.openAssignment(context))
        provideContent {
            if (useDynamic) GlanceTheme { ReadinessWidgetContent(snapshot, useDynamic, clickAction) }
            else ReadinessWidgetContent(snapshot, useDynamic, clickAction)
        }
    }
}

@Composable
private fun ReadinessWidgetContent(
    snapshot: ReadinessWidgetSnapshot?,
    useDynamic: Boolean,
    clickAction: androidx.glance.action.Action,
) {
    val topItem = snapshot?.items
        ?.filter { it.countdownValue != null }
        ?.minByOrNull { it.countdownValue ?: Int.MAX_VALUE }
        ?: snapshot?.items?.firstOrNull()

    WidgetSurface(useDynamic = useDynamic) {
        Column(modifier = GlanceModifier.clickable(clickAction)) {
            WidgetTitle(snapshot?.activeBaseName ?: "Readiness", useDynamic)
            Spacer(modifier = GlanceModifier.height(4.dp))
            if (topItem != null) {
                val countdown = topItem.countdownValue?.let { "$it ${topItem.countdownLabel}" } ?: topItem.countdownLabel
                WidgetAccent(countdown, useDynamic)
                WidgetSubtitle(topItem.title, useDynamic)
            } else {
                WidgetSubtitle("Set dates in Assignment", useDynamic)
            }
        }
    }
}

class ReadinessGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ReadinessGlanceWidget()
}
