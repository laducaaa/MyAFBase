package com.ryanladuca.myafbase.ui.tools

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.prefs.PFRAProfile
import com.ryanladuca.myafbase.domain.logic.PFRACardioEvent
import com.ryanladuca.myafbase.domain.logic.PFRAComponentScore
import com.ryanladuca.myafbase.domain.logic.PFRACoreEvent
import com.ryanladuca.myafbase.domain.logic.PFRAGender
import com.ryanladuca.myafbase.domain.logic.PFRAResult
import com.ryanladuca.myafbase.domain.logic.PFRAScoring
import com.ryanladuca.myafbase.domain.logic.PFRAStrengthEvent
import com.ryanladuca.myafbase.ui.components.M3NestedSurface
import com.ryanladuca.myafbase.ui.components.M3SurfaceCard
import com.ryanladuca.myafbase.ui.components.CapsuleProgressBar
import com.ryanladuca.myafbase.ui.components.StatusPill
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppMotion
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.ui.theme.appSemanticColors
import com.ryanladuca.myafbase.ui.theme.heroNumberTypography
import kotlin.math.roundToInt

@Composable
fun PfraProfileCard(
    profile: PFRAProfile,
    onChange: (PFRAProfile) -> Unit,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text("Profile", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text("Gender", style = MaterialTheme.typography.labelLarge)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PFRAGender.entries.forEach { g ->
                    FilterChip(
                        selected = profile.gender == g,
                        onClick = { onChange(profile.copy(gender = g)) },
                        label = { Text(g.name.lowercase().replaceFirstChar { it.uppercase() }) },
                        colors = AppChipDefaults.filterChip(selected = profile.gender == g),
                    )
                }
            }
            PfraStepperRow("Age", profile.age, 17, 75) { onChange(profile.copy(age = it)) }
        }
    }
}

@Composable
fun PfraBodyCompositionCard(
    profile: PFRAProfile,
    score: PFRAComponentScore?,
    onChange: (PFRAProfile) -> Unit,
    goalInline: @Composable (() -> Unit)? = null,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text("Body composition", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(AppTokens.sectionSpacing),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PfraCompactStepper(
                    label = "Ft",
                    valueText = "${profile.heightFeet}'",
                    onDecrement = {
                        onChange(profile.copy(heightFeet = (profile.heightFeet - 1).coerceAtLeast(4)))
                    },
                    onIncrement = {
                        onChange(profile.copy(heightFeet = (profile.heightFeet + 1).coerceAtMost(7)))
                    },
                )
                PfraCompactStepper(
                    label = "In",
                    valueText = "${profile.heightInches}\"",
                    onDecrement = {
                        onChange(profile.copy(heightInches = (profile.heightInches - 1).coerceAtLeast(0)))
                    },
                    onIncrement = {
                        onChange(profile.copy(heightInches = (profile.heightInches + 1).coerceAtMost(11)))
                    },
                )
            }
            PfraStepperRow("Waist (0.1\")", profile.waistTenths, 200, 600) {
                onChange(profile.copy(waistTenths = it))
            }
            Text(
                "Waist ${"%.1f".format(profile.waistInches)}\"",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            score?.let { PfraComponentScoreInline(it) }
            goalInline?.invoke()
        }
    }
}

@Composable
fun PfraCardioCard(
    profile: PFRAProfile,
    score: PFRAComponentScore?,
    onChange: (PFRAProfile) -> Unit,
    goalInline: @Composable (() -> Unit)? = null,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text("Cardio", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            PfraExerciseDropdown(
                label = "Exercise",
                selectedTitle = profile.cardioEvent.title,
                options = PFRACardioEvent.entries.map { it.title },
                onSelect = { title ->
                    PFRACardioEvent.entries.find { it.title == title }?.let {
                        onChange(profile.copy(cardioEvent = it))
                    }
                },
            )
            when (profile.cardioEvent) {
                PFRACardioEvent.TWO_MILE_RUN -> {
                    var runText by remember(profile.runMinutes, profile.runSeconds) {
                        mutableStateOf(PFRAScoring.formatRunTime(profile.cardioValue))
                    }
                    OutlinedTextField(
                        value = runText,
                        onValueChange = { runText = it },
                        label = { Text("2-mile time (mm:ss)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        supportingText = {
                            PFRAScoring.parseRunTime(runText)?.let {
                                Text("Parsed: ${PFRAScoring.formatRunTime(it)}")
                            } ?: if (runText.isNotBlank()) {
                                Text("Use format like 13:30", color = MaterialTheme.colorScheme.error)
                            } else {
                                null
                            }
                        },
                        shape = AppTextFieldDefaults.shape,
                        colors = AppTextFieldDefaults.colors(),
                    )
                    Button(
                        onClick = {
                            PFRAScoring.parseRunTime(runText)?.let { seconds ->
                                onChange(
                                    profile.copy(
                                        runMinutes = (seconds / 60).toInt(),
                                        runSeconds = (seconds % 60).roundToInt(),
                                    ),
                                )
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = AppButtonDefaults.primary(),
                        shape = MaterialTheme.shapes.small,
                    ) { Text("Apply run time") }
                }
                PFRACardioEvent.HAMR -> {
                    PfraStepperRow("HAMR shuttles", profile.hamrShuttles, 0, 120) {
                        onChange(profile.copy(hamrShuttles = it))
                    }
                }
            }
            score?.let { PfraComponentScoreInline(it) }
            goalInline?.invoke()
        }
    }
}

@Composable
fun PfraStrengthCard(
    profile: PFRAProfile,
    score: PFRAComponentScore?,
    onChange: (PFRAProfile) -> Unit,
    goalInline: @Composable (() -> Unit)? = null,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text("Strength", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            PfraExerciseDropdown(
                label = "Exercise",
                selectedTitle = profile.strengthEvent.title,
                options = PFRAStrengthEvent.entries.map { it.title },
                onSelect = { title ->
                    PFRAStrengthEvent.entries.find { it.title == title }?.let {
                        onChange(profile.copy(strengthEvent = it))
                    }
                },
            )
            PfraStepperRow("Reps", profile.strengthReps, 0, 120) {
                onChange(profile.copy(strengthReps = it))
            }
            score?.let { PfraComponentScoreInline(it) }
            goalInline?.invoke()
        }
    }
}

@Composable
fun PfraCoreCard(
    profile: PFRAProfile,
    score: PFRAComponentScore?,
    onChange: (PFRAProfile) -> Unit,
    goalInline: @Composable (() -> Unit)? = null,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text("Core", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            PfraExerciseDropdown(
                label = "Exercise",
                selectedTitle = profile.coreEvent.title,
                options = PFRACoreEvent.entries.map { it.title },
                onSelect = { title ->
                    PFRACoreEvent.entries.find { it.title == title }?.let {
                        onChange(profile.copy(coreEvent = it))
                    }
                },
            )
            when (profile.coreEvent) {
                PFRACoreEvent.FOREARM_PLANK -> {
                    var plankText by remember(profile.plankMinutes, profile.plankSeconds) {
                        mutableStateOf(PFRAScoring.formatPlankTime(profile.coreValue))
                    }
                    OutlinedTextField(
                        value = plankText,
                        onValueChange = { plankText = it },
                        label = { Text("Plank time (m:ss or seconds)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = AppTextFieldDefaults.shape,
                        colors = AppTextFieldDefaults.colors(),
                    )
                    Button(
                        onClick = {
                            PFRAScoring.parsePlankTime(plankText)?.let { seconds ->
                                onChange(
                                    profile.copy(
                                        plankMinutes = (seconds / 60).toInt(),
                                        plankSeconds = (seconds % 60).roundToInt(),
                                    ),
                                )
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = AppButtonDefaults.primary(),
                        shape = MaterialTheme.shapes.small,
                    ) { Text("Apply plank time") }
                }
                else -> {
                    PfraStepperRow("Reps", profile.coreReps, 0, 120) {
                        onChange(profile.copy(coreReps = it))
                    }
                }
            }
            score?.let { PfraComponentScoreInline(it) }
            goalInline?.invoke()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PfraExerciseDropdown(
    label: String,
    selectedTitle: String,
    options: List<String>,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it },
        modifier = modifier.fillMaxWidth(),
    ) {
        OutlinedTextField(
            value = selectedTitle,
            onValueChange = {},
            readOnly = true,
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth(),
            shape = AppTextFieldDefaults.shape,
            colors = AppTextFieldDefaults.colors(),
        )
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
        ) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(option) },
                    onClick = {
                        onSelect(option)
                        expanded = false
                    },
                )
            }
        }
    }
}

@Composable
fun PfraCompositeSummaryCard(
    composite: Double,
    target: Double,
    passed: Boolean,
    rating: String,
    verdictTitle: String,
    verdictSubtitle: String,
    progressLabel: String,
    passingLabel: String,
    insight: String?,
) {
    val colors = appSemanticColors()
    val progress = (composite / target).coerceIn(0.0, 1.0).toFloat()
    val animatedProgress by animateFloatAsState(progress, animationSpec = AppMotion.scoreBarTween, label = "composite")
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text(verdictTitle, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text(
                verdictSubtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Bottom,
            ) {
                Column {
                    Text("Composite", style = MaterialTheme.typography.labelSmall)
                    Text(
                        "%.1f".format(composite),
                        style = heroNumberTypography(),
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(progressLabel, style = MaterialTheme.typography.labelSmall)
                    Text(
                        "%.1f".format(target),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            CapsuleProgressBar(
                progress = animatedProgress,
                height = 8.dp,
                fillColor = if (passed || composite >= target) colors.success else colors.accent,
            )
            Text(
                if (passed || composite >= target) {
                    passingLabel
                } else {
                    "$rating · need ${"%.1f".format((target - composite).coerceAtLeast(0.0))} more"
                },
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
            )
            insight?.takeIf { it.isNotBlank() }?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
fun PfraComponentScoreInline(score: PFRAComponentScore) {
    val colors = appSemanticColors()
    val minimum = if (score.name == "Cardio") PFRAScoring.CARDIO_MINIMUM else PFRAScoring.COMPONENT_MINIMUM
    val progress = (score.points / score.maxPoints).coerceIn(0.0, 1.0).toFloat()
    val animatedProgress by animateFloatAsState(progress, animationSpec = AppMotion.scoreBarTween, label = "component")
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(AppTokens.microGap + 2.dp),
    ) {
        HorizontalDivider()
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "%.1f".format(score.points),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (score.passed) MaterialTheme.colorScheme.onSurface else colors.warning,
            )
            Text(
                " / ${score.maxPoints.toInt()} pts",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Box(modifier = Modifier.weight(1f))
            StatusPill(
                text = if (score.passed) "Passes" else "Below min",
                emphasis = true,
                tint = if (score.passed) colors.success else colors.warning,
            )
        }
        CapsuleProgressBar(
            progress = animatedProgress,
            fillColor = if (score.passed) colors.success else colors.warning,
        )
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(
                score.detail,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f),
            )
            if (!score.passed) {
                Text(
                    "Need ${"%.1f".format(minimum)}+",
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.warning,
                )
            }
        }
    }
}

@Composable
fun PfraDisclaimerCard(goalsMode: Boolean) {
    M3NestedSurface {
        Text(
            if (goalsMode) {
                "Unofficial estimate based on March 2026 PFRA charts. Assumes other component scores stay the same."
            } else {
                "Unofficial estimate based on March 2026 PFRA charts. Pass requires 75.0 composite and all component minimums (35 cardio, 2.5 others)."
            },
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun PfraStepperRow(label: String, value: Int, min: Int, max: Int, onChange: (Int) -> Unit) {
    val colors = appSemanticColors()
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            PfraStepperButton(size = 32.dp, onClick = { onChange((value - 1).coerceAtLeast(min)) }) {
                Icon(
                    Icons.Default.Remove,
                    contentDescription = "Decrease",
                    tint = colors.accent,
                    modifier = Modifier.size(18.dp),
                )
            }
            Text(
                "$value",
                modifier = Modifier.padding(horizontal = 8.dp),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
            PfraStepperButton(size = 32.dp, onClick = { onChange((value + 1).coerceAtMost(max)) }) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = "Increase",
                    tint = colors.accent,
                    modifier = Modifier.size(18.dp),
                )
            }
        }
    }
}

@Composable
private fun PfraCompactStepper(
    label: String,
    valueText: String,
    onDecrement: () -> Unit,
    onIncrement: () -> Unit,
) {
    val colors = appSemanticColors()
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(label, style = MaterialTheme.typography.labelSmall)
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            PfraStepperButton(size = 28.dp, onClick = onDecrement) {
                Icon(
                    Icons.Default.Remove,
                    contentDescription = "Decrease",
                    tint = colors.accent,
                    modifier = Modifier.size(16.dp),
                )
            }
            Text(
                valueText,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
            PfraStepperButton(size = 28.dp, onClick = onIncrement) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = "Increase",
                    tint = colors.accent,
                    modifier = Modifier.size(16.dp),
                )
            }
        }
    }
}

@Composable
private fun PfraStepperButton(
    onClick: () -> Unit,
    size: Dp = 32.dp,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.surfaceContainerHighest)
            .clickable(role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        content()
    }
}

fun pfraAssessment(profile: PFRAProfile) =
    if (profile.heightTotalInches > 0 && profile.waistInches > 0) {
        PFRAScoring.evaluate(
            gender = profile.gender,
            age = profile.age,
            heightInches = profile.heightTotalInches,
            waistInches = profile.waistInches,
            cardioEvent = profile.cardioEvent,
            cardioValue = profile.cardioValue,
            strengthEvent = profile.strengthEvent,
            strengthReps = profile.strengthReps,
            coreEvent = profile.coreEvent,
            coreValue = profile.coreValue,
        )
    } else {
        null
    }

fun componentScore(result: PFRAResult, name: String): PFRAComponentScore? =
    result.componentScores.firstOrNull { it.name == name }
