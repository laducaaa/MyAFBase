package com.ryanladuca.myafbase.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.ui.theme.WeatherHeroTheme
import kotlin.math.abs

@Composable
fun WeatherHeroSection(
    base: Base,
    showWeather: Boolean,
    weatherThemeKey: String?,
    weatherConditionLabel: String?,
    temperatureF: Int?,
    feelsLikeF: Int? = null,
    windMph: Int? = null,
    humidity: Int? = null,
    weatherLoading: Boolean,
    onRefresh: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val palette = WeatherHeroTheme.palette(weatherThemeKey)
    val scheme = MaterialTheme.colorScheme
    val subtitle = listOfNotNull(
        base.location.takeIf { it.isNotBlank() },
        base.wing.takeIf { it.isNotBlank() },
    ).joinToString(" · ")

    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = scheme.surfaceContainerHigh,
        tonalElevation = 1.dp,
    ) {
        Box {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                scheme.primary.copy(alpha = 0.10f),
                                scheme.secondary.copy(alpha = 0.06f),
                                Color.Transparent,
                            ),
                            start = Offset.Zero,
                            end = Offset(900f, 500f),
                        ),
                    ),
            )
            Surface(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(24.dp)
                    .size(80.dp),
                shape = CircleShape,
                color = scheme.primaryContainer,
                tonalElevation = 0.dp,
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = palette.symbol,
                        contentDescription = null,
                        tint = scheme.onPrimaryContainer,
                        modifier = Modifier.size(40.dp),
                    )
                }
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 24.dp)
                    .padding(end = 88.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.Top,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = base.name,
                            style = MaterialTheme.typography.headlineSmall,
                            color = scheme.onSurface,
                            fontWeight = FontWeight.SemiBold,
                        )
                        if (subtitle.isNotBlank()) {
                            Text(
                                text = subtitle,
                                style = MaterialTheme.typography.bodyMedium,
                                color = scheme.onSurfaceVariant,
                            )
                        }
                    }
                    if (showWeather && onRefresh != null) {
                        IconButton(
                            onClick = onRefresh,
                            enabled = !weatherLoading,
                        ) {
                            if (weatherLoading) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(20.dp),
                                    strokeWidth = 2.dp,
                                    color = scheme.primary,
                                )
                            } else {
                                Icon(
                                    Icons.Default.Refresh,
                                    contentDescription = "Refresh weather",
                                    tint = scheme.primary,
                                )
                            }
                        }
                    }
                }

                if (showWeather) {
                    Spacer(modifier = Modifier.height(4.dp))
                    when {
                        weatherLoading -> WeatherHeroSkeleton()
                        temperatureF != null -> {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 4.dp),
                                verticalAlignment = Alignment.Bottom,
                                horizontalArrangement = Arrangement.spacedBy(16.dp),
                            ) {
                                Text(
                                    text = "$temperatureF°",
                                    style = MaterialTheme.typography.displayLarge,
                                    color = scheme.primary,
                                    fontWeight = FontWeight.Medium,
                                )
                                Column(modifier = Modifier.padding(bottom = 8.dp)) {
                                    Text(
                                        text = weatherConditionLabel.orEmpty().ifBlank { "—" },
                                        style = MaterialTheme.typography.titleMedium,
                                        color = scheme.onSurface,
                                        fontWeight = FontWeight.SemiBold,
                                    )
                                    val showFeels = feelsLikeF != null && abs(feelsLikeF - temperatureF) >= 2
                                    if (showFeels) {
                                        Text(
                                            text = "Feels like $feelsLikeF°",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = scheme.onSurfaceVariant,
                                        )
                                    }
                                }
                            }
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 4.dp, bottom = 4.dp),
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                            ) {
                                WeatherMetricChip(
                                    icon = Icons.Default.Air,
                                    value = windMph?.let { "$it mph" } ?: "--",
                                    label = "Wind",
                                    modifier = Modifier.weight(1f),
                                )
                                WeatherMetricChip(
                                    icon = Icons.Default.WaterDrop,
                                    value = humidity?.let { "$it%" } ?: "--",
                                    label = "Humidity",
                                    modifier = Modifier.weight(1f),
                                )
                            }
                        }
                        else -> {
                            Text(
                                "Weather unavailable",
                                style = MaterialTheme.typography.bodyMedium,
                                color = scheme.onSurfaceVariant,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun WeatherMetricChip(
    icon: ImageVector,
    value: String,
    label: String,
    modifier: Modifier = Modifier,
) {
    val scheme = MaterialTheme.colorScheme
    Surface(
        modifier = modifier,
        shape = MaterialTheme.shapes.large,
        color = scheme.surfaceContainerHighest,
        tonalElevation = 0.dp,
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = scheme.primary,
                modifier = Modifier.size(18.dp),
            )
            Column {
                Text(
                    value,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = scheme.onSurface,
                )
                Text(
                    label,
                    style = MaterialTheme.typography.labelSmall,
                    color = scheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun WeatherHeroSkeleton() {
    val scheme = MaterialTheme.colorScheme
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SkeletonBar(width = 120.dp, height = 48.dp)
        SkeletonBar(width = 96.dp, height = 16.dp)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            SkeletonBar(modifier = Modifier.weight(1f), height = 52.dp)
            SkeletonBar(modifier = Modifier.weight(1f), height = 52.dp)
        }
        Text(
            "Loading weather…",
            color = scheme.onSurfaceVariant,
            style = MaterialTheme.typography.bodySmall,
        )
    }
}

@Composable
private fun SkeletonBar(
    width: androidx.compose.ui.unit.Dp,
    height: androidx.compose.ui.unit.Dp,
) {
  SkeletonBar(modifier = Modifier.width(width), height = height)
}

@Composable
private fun SkeletonBar(
    modifier: Modifier = Modifier,
    height: androidx.compose.ui.unit.Dp,
) {
    val scheme = MaterialTheme.colorScheme
    Box(
        modifier = modifier
            .height(height)
            .clip(RoundedCornerShape(12.dp))
            .background(scheme.onSurface.copy(alpha = 0.08f)),
    )
}
