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

class WeatherGlanceWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = loadWidgetStore(context)?.loadWeather()
        val useDynamic = useDynamicColors()
        val clickAction = actionStartActivity(WidgetActions.openHome(context))
        provideContent {
            if (useDynamic) GlanceTheme { WeatherWidgetContent(snapshot, useDynamic, clickAction) }
            else WeatherWidgetContent(snapshot, useDynamic, clickAction)
        }
    }
}

@Composable
private fun WeatherWidgetContent(
    snapshot: WeatherWidgetSnapshot?,
    useDynamic: Boolean,
    clickAction: androidx.glance.action.Action,
) {
    WidgetSurface(useDynamic = useDynamic) {
        Column(modifier = GlanceModifier.clickable(clickAction)) {
            WidgetTitle(snapshot?.baseName ?: "MyAFBase", useDynamic)
            Spacer(modifier = GlanceModifier.height(4.dp))
            if (snapshot?.isAvailable == true) {
                WidgetAccent("${snapshot.tempDisplay} ${snapshot.conditionName}", useDynamic)
                snapshot.location?.let { WidgetSubtitle(it, useDynamic) }
            } else {
                WidgetSubtitle("Weather unavailable", useDynamic)
            }
        }
    }
}

class WeatherGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = WeatherGlanceWidget()
}
