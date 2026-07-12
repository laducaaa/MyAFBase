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

class OpenNowGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = loadWidgetStore(context)?.loadOpenNow()
        val useDynamic = useDynamicColors()
        val clickAction = actionStartActivity(WidgetActions.openExplore(context))
        provideContent {
            if (useDynamic) GlanceTheme { OpenNowWidgetContent(snapshot, useDynamic, clickAction) }
            else OpenNowWidgetContent(snapshot, useDynamic, clickAction)
        }
    }
}

@Composable
private fun OpenNowWidgetContent(
    snapshot: OpenNowWidgetSnapshot?,
    useDynamic: Boolean,
    clickAction: androidx.glance.action.Action,
) {
    WidgetSurface(useDynamic = useDynamic) {
        Column(modifier = GlanceModifier.clickable(clickAction)) {
            WidgetTitle(snapshot?.baseName ?: "Open Now", useDynamic)
            Spacer(modifier = GlanceModifier.height(4.dp))
            WidgetAccent(snapshot?.summaryText ?: "Tap to explore", useDynamic)
            snapshot?.items?.firstOrNull()?.let { first ->
                WidgetSubtitle("${first.name} · ${first.categoryLabel}", useDynamic)
            }
        }
    }
}

class OpenNowGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = OpenNowGlanceWidget()
}
