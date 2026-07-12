package com.ryanladuca.myafbase.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.ui.theme.appSemanticColors

@Composable
fun BasePickerChip(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    centered: Boolean = false
) {
    val appState = LocalAppState.current
    val base by appState.currentBase.collectAsState()
    val label = base?.name ?: "Select base"
    val selected = base != null
    FilterChip(
        onClick = onClick,
        selected = selected,
        label = {
            Text(
                text = label,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        },
        leadingIcon = { Icon(Icons.Default.Place, contentDescription = null) },
        trailingIcon = { Icon(Icons.Default.ExpandMore, contentDescription = null) },
        colors = AppChipDefaults.filterChip(selected = selected),
        modifier = modifier
    )
}

@Composable
fun SectionCard(
    title: String,
    subtitle: String? = null,
    onClick: (() -> Unit)? = null,
    content: @Composable (() -> Unit)? = null
) {
    M3SurfaceCard(onClick = onClick) {
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        if (subtitle != null) {
            Text(
                subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        content?.invoke()
    }
}

@Composable
fun EmptyBasePrompt(onPickBase: () -> Unit, contentPadding: PaddingValues = PaddingValues()) {
    Column(
        Modifier
            .fillMaxSize()
            .padding(contentPadding)
            .padding(AppTokens.sectionSpacing),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)
    ) {
        Text("No base selected", style = MaterialTheme.typography.titleLarge)
        Text(
            "Pick your installation to load gates, resources, and assignment tools.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        FilledTonalButton(
            onClick = onPickBase,
            colors = AppButtonDefaults.tonal(),
            shape = MaterialTheme.shapes.small,
        ) {
            Text("Choose base")
        }
    }
}

@Composable
fun KeyValueRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun StatusPill(
    text: String,
    emphasis: Boolean = false,
    tint: Color = appSemanticColors().success,
) {
    Surface(
        shape = MaterialTheme.shapes.extraLarge,
        color = tint.copy(alpha = 0.14f),
        contentColor = tint,
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = if (emphasis) FontWeight.SemiBold else FontWeight.Medium,
            color = tint,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = AppTokens.microGap),
        )
    }
}

@Composable
fun CapsuleProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    height: Dp = 6.dp,
    trackColor: Color = MaterialTheme.colorScheme.surfaceVariant,
    fillColor: Color = appSemanticColors().success,
) {
    LinearProgressIndicator(
        progress = { progress.coerceIn(0f, 1f) },
        modifier = modifier
            .fillMaxWidth()
            .height(height),
        color = fillColor,
        trackColor = trackColor,
        strokeCap = StrokeCap.Round,
    )
}
