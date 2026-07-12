package com.ryanladuca.myafbase.ui.assignment

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.Security
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.ReadinessEntity
import com.ryanladuca.myafbase.domain.logic.ReadinessStatus
import com.ryanladuca.myafbase.ui.components.M3SurfaceCard
import java.text.SimpleDateFormat
import java.util.Date

@Composable
fun ReadinessTrackerSection(
    readiness: ReadinessEntity?,
    dateFormat: SimpleDateFormat,
    onPickField: (String) -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val items = listOf(
        ReadinessRowData("fitness", "Fitness test", Icons.Default.DirectionsRun, readiness?.fitnessTestDueMillis),
        ReadinessRowData("dental", "Dental", Icons.Default.MedicalServices, readiness?.dentalDueMillis),
        ReadinessRowData("eval", "Eval closeout", Icons.Default.Event, readiness?.evalCloseoutDueMillis),
        ReadinessRowData("cac", "CAC expiration", Icons.Default.Badge, readiness?.cacExpirationMillis),
        ReadinessRowData("clearance", "Clearance renewal", Icons.Default.Security, readiness?.clearanceRenewalMillis),
    )

    M3SurfaceCard(contentPadding = 0.dp) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text("Readiness tracker", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    "Fitness, dental, eval, CAC, and clearance due dates.",
                    style = MaterialTheme.typography.bodySmall,
                    color = scheme.onSurfaceVariant,
                )
            }
            HorizontalDivider(color = scheme.outlineVariant)
            items.forEachIndexed { index, item ->
                ReadinessListItem(
                    item = item,
                    dateFormat = dateFormat,
                    onClick = { onPickField(item.field) },
                )
                if (index < items.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        color = scheme.outlineVariant,
                    )
                }
            }
            val pcsStatus = ReadinessStatus.evaluatePcsWindow(
                readiness?.pcsWindowStartMillis,
                readiness?.pcsWindowEndMillis,
            )
            if (pcsStatus != ReadinessStatus.NOT_SET) {
                HorizontalDivider(color = scheme.outlineVariant)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("PCS window", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                    ReadinessStatusChip(status = pcsStatus)
                }
            }
        }
    }
}

@Composable
private fun ReadinessListItem(
    item: ReadinessRowData,
    dateFormat: SimpleDateFormat,
    onClick: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val status = ReadinessStatus.evaluate(item.millis)
    val (containerColor, contentColor) = readinessIconColors(status, scheme)

    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick),
        colors = ListItemDefaults.colors(containerColor = scheme.surfaceContainerHigh),
        leadingContent = {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = containerColor,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    imageVector = item.icon,
                    contentDescription = null,
                    tint = contentColor,
                    modifier = Modifier
                        .padding(10.dp)
                        .size(20.dp),
                )
            }
        },
        headlineContent = {
            Text(item.label, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
        },
        supportingContent = {
            Text(
                item.millis?.let { dateFormat.format(Date(it)) } ?: "Not set",
                style = MaterialTheme.typography.bodySmall,
                color = scheme.onSurfaceVariant,
            )
        },
        trailingContent = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                ReadinessStatusChip(status = status)
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = scheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 4.dp),
                )
            }
        },
    )
}

@Composable
private fun ReadinessStatusChip(status: ReadinessStatus) {
    val scheme = MaterialTheme.colorScheme
    val (containerColor, contentColor) = when (status) {
        ReadinessStatus.OVERDUE -> scheme.errorContainer to scheme.onErrorContainer
        ReadinessStatus.DUE_SOON -> scheme.tertiaryContainer to scheme.onTertiaryContainer
        ReadinessStatus.ON_TRACK -> scheme.primaryContainer to scheme.onPrimaryContainer
        ReadinessStatus.WINDOW_OPEN -> scheme.secondaryContainer to scheme.onSecondaryContainer
        ReadinessStatus.NOT_SET -> scheme.surfaceContainerHighest to scheme.onSurfaceVariant
    }
    Surface(
        shape = MaterialTheme.shapes.small,
        color = containerColor,
        tonalElevation = 0.dp,
    ) {
        Text(
            text = status.label,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = contentColor,
        )
    }
}

private fun readinessIconColors(
    status: ReadinessStatus,
    scheme: androidx.compose.material3.ColorScheme,
): Pair<Color, Color> = when (status) {
    ReadinessStatus.OVERDUE -> scheme.errorContainer to scheme.onErrorContainer
    ReadinessStatus.DUE_SOON -> scheme.tertiaryContainer to scheme.onTertiaryContainer
    ReadinessStatus.ON_TRACK -> scheme.primaryContainer to scheme.onPrimaryContainer
    ReadinessStatus.WINDOW_OPEN -> scheme.secondaryContainer to scheme.onSecondaryContainer
    ReadinessStatus.NOT_SET -> scheme.surfaceContainerHighest to scheme.onSurfaceVariant
}

private data class ReadinessRowData(
    val field: String,
    val label: String,
    val icon: ImageVector,
    val millis: Long?,
)
