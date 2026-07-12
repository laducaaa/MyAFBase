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
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.FlightTakeoff
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material3.Checkbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.logic.PCSChecklistItem
import com.ryanladuca.myafbase.domain.model.AssignmentSegment
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.ui.components.M3NestedSurface
import com.ryanladuca.myafbase.ui.components.M3SurfaceCard
import com.ryanladuca.myafbase.ui.theme.AppTokens
import java.text.SimpleDateFormat
import java.util.Date

data class OutboundLocation(val title: String, val detail: String, val icon: ImageVector = Icons.Default.FlightTakeoff)

val commonOutboundLocations = listOf(
    OutboundLocation("Finance / Outbound CSS", "Final LES, travel voucher, and leave balance.", Icons.Default.AccountBalance),
    OutboundLocation("MPF / vMPF", "Out-processing checklist and personnel actions.", Icons.Default.People),
    OutboundLocation("TMO", "Household goods and storage.", Icons.Default.FlightTakeoff),
    OutboundLocation("Medical / Dental", "Final exams and records transfer.", Icons.Default.LocalHospital),
    OutboundLocation("ID Card / DEERS", "CAC turn-in or transfer as required.", Icons.Default.Badge),
    OutboundLocation("Housing", "Move-out inspection and clearance.", Icons.Default.Home),
)

@Composable
fun AssignmentPhaseHeader(base: Base, phase: AssignmentSegment) {
    val scheme = MaterialTheme.colorScheme
    val (containerColor, contentColor, eyebrow, headline, subtitle) = when (phase) {
        AssignmentSegment.INBOUND -> PhaseStyle(
            scheme.tertiaryContainer,
            scheme.onTertiaryContainer,
            "IN PROCESSING",
            "In processing at ${base.name}",
            "Checklists and newcomer guides for your arrival.",
        )
        AssignmentSegment.STATIONED -> PhaseStyle(
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            "STATIONED",
            "Stationed at ${base.name}",
            "Track readiness dates and stay mission-ready.",
        )
        AssignmentSegment.OUTBOUND -> PhaseStyle(
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
            "OUT PROCESSING",
            "Out processing from ${base.name}",
            "PCS tools, checklist, and out-processing locations.",
        )
    }
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = containerColor,
        tonalElevation = 0.dp,
    ) {
        Column(
            modifier = Modifier.padding(AppTokens.contentPadding),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(eyebrow, style = MaterialTheme.typography.labelSmall, color = contentColor, fontWeight = FontWeight.SemiBold)
            Text(headline, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = contentColor)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = contentColor.copy(alpha = 0.88f))
            base.description.takeIf { it.isNotBlank() }?.let { description ->
                M3NestedSurface {
                    Text(
                        description,
                        style = MaterialTheme.typography.bodySmall,
                        maxLines = 3,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

private data class PhaseStyle(
    val containerColor: Color,
    val contentColor: Color,
    val eyebrow: String,
    val headline: String,
    val subtitle: String,
)

@Composable
fun AssignmentPhaseTipBanner() {
    var dismissed by remember { mutableStateOf(false) }
    if (dismissed) return
    val scheme = MaterialTheme.colorScheme
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.large,
        color = scheme.secondaryContainer,
        tonalElevation = 0.dp,
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(Icons.Default.Info, contentDescription = null, tint = scheme.onSecondaryContainer)
            Text(
                "Set phase under Menu → Installation.",
                modifier = Modifier.weight(1f),
                style = MaterialTheme.typography.bodySmall,
                color = scheme.onSecondaryContainer,
            )
            IconButton(onClick = { dismissed = true }) {
                Icon(Icons.Default.Close, contentDescription = "Dismiss", tint = scheme.onSecondaryContainer)
            }
        }
    }
}

@Composable
fun AssignmentDatesCard(
    phase: AssignmentSegment,
    reportMillis: Long?,
    pcsMillis: Long?,
    dateFormat: SimpleDateFormat,
    onPickReport: () -> Unit,
    onPickPcs: () -> Unit,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text("Key dates", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text(
                when (phase) {
                    AssignmentSegment.INBOUND -> "Report date drives your inbound checklist."
                    AssignmentSegment.STATIONED -> "PCS date powers Home countdown within ~4 months."
                    AssignmentSegment.OUTBOUND -> "PCS date feeds Leave Planner pacing."
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            when (phase) {
                AssignmentSegment.INBOUND -> {
                    OutlinedButton(onClick = onPickReport, modifier = Modifier.fillMaxWidth()) {
                        Text("Report: ${reportMillis?.let { dateFormat.format(Date(it)) } ?: "Not set"}")
                    }
                }
                AssignmentSegment.STATIONED -> {
                    OutlinedButton(onClick = onPickReport, modifier = Modifier.fillMaxWidth()) {
                        Text("Report: ${reportMillis?.let { dateFormat.format(Date(it)) } ?: "Not set"}")
                    }
                    OutlinedButton(onClick = onPickPcs, modifier = Modifier.fillMaxWidth()) {
                        Text("PCS: ${pcsMillis?.let { dateFormat.format(Date(it)) } ?: "Not set"}")
                    }
                }
                AssignmentSegment.OUTBOUND -> {
                    OutlinedButton(onClick = onPickPcs, modifier = Modifier.fillMaxWidth()) {
                        Text("PCS: ${pcsMillis?.let { dateFormat.format(Date(it)) } ?: "Not set"}")
                    }
                }
            }
        }
    }
}

@Composable
fun AssignmentNextBaseCard(onChangeBase: () -> Unit) {
    M3SurfaceCard(onClick = onChangeBase) {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.microGap)) {
            Text("Next assignment", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text(
                "Change your gaining installation when orders firm up.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
fun AssignmentToolLinksCard(
    onLeavePlanner: () -> Unit,
    onPfraGoals: () -> Unit,
    onPfraScore: () -> Unit = {},
) {
    val scheme = MaterialTheme.colorScheme
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("PCS tools", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            AssignmentToolRow(Icons.Default.DirectionsRun, "PFRA Score Calculator", scheme.tertiaryContainer, scheme.onTertiaryContainer, onPfraScore)
            HorizontalDivider(color = scheme.outlineVariant, modifier = Modifier.padding(start = 52.dp))
            AssignmentToolRow(Icons.Default.TrackChanges, "PFRA Goal Planner", scheme.primaryContainer, scheme.onPrimaryContainer, onPfraGoals)
            HorizontalDivider(color = scheme.outlineVariant, modifier = Modifier.padding(start = 52.dp))
            AssignmentToolRow(Icons.Default.CalendarMonth, "Leave Planner", scheme.secondaryContainer, scheme.onSecondaryContainer, onLeavePlanner)
        }
    }
}

@Composable
fun AssignmentChecklistGroup(
    items: List<PCSChecklistItem>,
    completedIds: Set<String>,
    onToggle: (String, Boolean) -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    M3SurfaceCard(contentPadding = 0.dp) {
        Column(modifier = Modifier.fillMaxWidth()) {
            items.forEachIndexed { index, item ->
                ListItem(
                    colors = ListItemDefaults.colors(containerColor = scheme.surfaceContainerHigh),
                    headlineContent = { Text(item.title) },
                    supportingContent = { item.detail?.let { Text(it) } },
                    leadingContent = {
                        Checkbox(
                            checked = completedIds.contains(item.id),
                            onCheckedChange = { checked -> onToggle(item.id, checked) },
                        )
                    },
                )
                if (index < items.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        color = scheme.outlineVariant,
                    )
                }
            }
        }
    }
}

@Composable
fun AssignmentChecklistCard(
    title: String,
    subtitle: String,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun AssignmentSectionCard(
    title: String,
    content: @Composable () -> Unit,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            content()
        }
    }
}

@Composable
private fun AssignmentToolRow(
    icon: ImageVector,
    title: String,
    containerColor: Color,
    contentColor: Color,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Surface(
            shape = MaterialTheme.shapes.medium,
            color = containerColor,
            tonalElevation = 0.dp,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = contentColor,
                modifier = Modifier
                    .padding(10.dp)
                    .size(20.dp),
            )
        }
        Text(
            title,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
        )
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null)
    }
}

@Composable
fun OutboundLocationsCard(locations: List<OutboundLocation>) {
    val scheme = MaterialTheme.colorScheme
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
            Text(
                "Out-processing locations",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(bottom = 8.dp),
            )
            locations.forEachIndexed { index, loc ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Surface(
                        shape = MaterialTheme.shapes.medium,
                        color = scheme.secondaryContainer,
                        tonalElevation = 0.dp,
                    ) {
                        Icon(
                            imageVector = loc.icon,
                            contentDescription = null,
                            tint = scheme.onSecondaryContainer,
                            modifier = Modifier
                                .padding(10.dp)
                                .size(20.dp),
                        )
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        Text(loc.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                        Text(
                            loc.detail,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                if (index < locations.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 52.dp),
                        color = scheme.outlineVariant,
                    )
                }
            }
        }
    }
}
