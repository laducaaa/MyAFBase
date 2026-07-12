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

class EmergencyGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = loadWidgetStore(context)?.loadEmergency()
        val useDynamic = useDynamicColors()
        val primary = snapshot?.contacts?.firstOrNull()
        val clickAction = if (primary != null) {
            actionStartActivity(WidgetActions.dialNumber(context, primary.number))
        } else {
            actionStartActivity(WidgetActions.openHome(context, showEmergency = true))
        }
        provideContent {
            if (useDynamic) GlanceTheme { EmergencyWidgetContent(snapshot, useDynamic, clickAction) }
            else EmergencyWidgetContent(snapshot, useDynamic, clickAction)
        }
    }
}

@Composable
private fun EmergencyWidgetContent(
    snapshot: EmergencyWidgetSnapshot?,
    useDynamic: Boolean,
    clickAction: androidx.glance.action.Action,
) {
    WidgetSurface(useDynamic = useDynamic) {
        Column(modifier = GlanceModifier.clickable(clickAction)) {
            WidgetTitle("Emergency", useDynamic)
            Spacer(modifier = GlanceModifier.height(4.dp))
            val primary = snapshot?.contacts?.firstOrNull()
            if (primary != null) {
                WidgetAccent(primary.label, useDynamic)
                WidgetSubtitle(primary.number, useDynamic)
            } else {
                WidgetSubtitle(snapshot?.baseName ?: "MyAFBase", useDynamic)
            }
        }
    }
}

class EmergencyGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = EmergencyGlanceWidget()
}
