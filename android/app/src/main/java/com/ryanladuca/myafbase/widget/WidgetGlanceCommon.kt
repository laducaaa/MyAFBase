package com.ryanladuca.myafbase.widget

import android.content.Context
import android.graphics.Color
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.ryanladuca.myafbase.MyAFBaseApplication

internal suspend fun loadWidgetStore(context: Context): WidgetDataStore? {
    val app = context.applicationContext as? MyAFBaseApplication ?: return null
    return app.container.widgetDataStore
}

@Composable
internal fun WidgetSurface(
    useDynamic: Boolean,
    content: @Composable () -> Unit,
) {
    val background = if (useDynamic) {
        GlanceTheme.colors.widgetBackground
    } else {
        ColorProvider(Color.parseColor("#1E1E20"))
    }
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(background)
            .padding(12.dp),
        verticalAlignment = Alignment.Top,
        horizontalAlignment = Alignment.Start,
    ) {
        content()
    }
}

@Composable
internal fun WidgetTitle(text: String, useDynamic: Boolean) {
    val color = if (useDynamic) GlanceTheme.colors.onSurface else ColorProvider(Color.WHITE)
    Text(
        text = text,
        style = TextStyle(
            color = color,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
        ),
    )
}

@Composable
internal fun WidgetSubtitle(text: String, useDynamic: Boolean) {
    val color = if (useDynamic) {
        GlanceTheme.colors.onSurfaceVariant
    } else {
        ColorProvider(Color.parseColor("#B0B0B5"))
    }
    Text(
        text = text,
        style = TextStyle(color = color, fontSize = 12.sp),
    )
}

@Composable
internal fun WidgetAccent(text: String, useDynamic: Boolean) {
    val color = if (useDynamic) GlanceTheme.colors.primary else ColorProvider(Color.parseColor("#6EC2FF"))
    Text(
        text = text,
        style = TextStyle(color = color, fontSize = 12.sp, fontWeight = FontWeight.Medium),
    )
}

internal fun useDynamicColors(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
