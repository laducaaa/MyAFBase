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

class PayGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = loadWidgetStore(context)?.loadPay()
        val useDynamic = useDynamicColors()
        val clickAction = actionStartActivity(WidgetActions.openTool(context, WidgetToolIds.PAY))
        provideContent {
            if (useDynamic) GlanceTheme { PayWidgetContent(snapshot, useDynamic, clickAction) }
            else PayWidgetContent(snapshot, useDynamic, clickAction)
        }
    }
}

@Composable
private fun PayWidgetContent(
    snapshot: PayWidgetSnapshot?,
    useDynamic: Boolean,
    clickAction: androidx.glance.action.Action,
) {
    WidgetSurface(useDynamic = useDynamic) {
        Column(modifier = GlanceModifier.clickable(clickAction)) {
            WidgetTitle("Next Pay", useDynamic)
            Spacer(modifier = GlanceModifier.height(4.dp))
            if (snapshot?.isAvailable == true) {
                WidgetAccent(snapshot.daysLabel, useDynamic)
                WidgetSubtitle(snapshot.nextTitle, useDynamic)
            } else {
                WidgetSubtitle("No upcoming pay", useDynamic)
            }
        }
    }
}

class PayGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = PayGlanceWidget()
}
