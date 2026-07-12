package com.ryanladuca.myafbase.ui.tools

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.logic.PFRAGoalPlanner
import com.ryanladuca.myafbase.domain.logic.PFRARecordKind
import com.ryanladuca.myafbase.domain.logic.PFRATargetTier
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.components.SectionCard
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch

@Composable
fun PfraGoalsScreen(contentPadding: PaddingValues) {
    val container = LocalAppContainer.current
    val profile by container.pfraProfileStore.profile.collectAsState()
    val scope = rememberCoroutineScope()
    var showSave by remember { mutableStateOf(false) }
    var saveNote by remember { mutableStateOf("") }

    val assessment = remember(profile) { pfraAssessment(profile) }
    val plan = remember(profile) {
        PFRAGoalPlanner.plan(
            target = profile.targetTier,
            gender = profile.gender,
            age = profile.age,
            heightInches = profile.heightTotalInches,
            waistInches = profile.waistInches,
            cardioEvent = profile.cardioEvent,
            cardioValue = profile.cardioValue,
            strengthEvent = profile.strengthEvent,
            strengthReps = profile.strengthReps,
            coreEvent = profile.coreEvent,
            coreValue = profile.coreValue
        )
    }

    fun componentTarget(name: String) = plan?.componentTargets?.firstOrNull { it.name == name }

    M3FlatScreenBackground {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding)
                .padding(AppTokens.screenPadding)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
        SectionCard(title = "What are you aiming for?") {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PFRATargetTier.entries.forEach { tier ->
                    FilterChip(
                        selected = profile.targetTier == tier,
                        onClick = { container.pfraProfileStore.update { it.copy(targetTier = tier) } },
                        label = { Text(tier.title) },
                        colors = com.ryanladuca.myafbase.ui.theme.AppChipDefaults.filterChip(
                            selected = profile.targetTier == tier,
                        ),
                    )
                }
            }
            Text(tierSubtitle(profile.targetTier))
        }

        plan?.let { p ->
            PfraCompositeSummaryCard(
                composite = p.currentComposite,
                target = p.targetComposite,
                passed = p.alreadyMet,
                rating = p.target.title,
                verdictTitle = if (p.alreadyMet) "Target met" else "Gap to ${p.target.title.lowercase()}",
                verdictSubtitle = "Current ${"%.1f".format(p.currentComposite)} → ${"%.1f".format(p.targetComposite)}",
                progressLabel = p.target.title,
                passingLabel = "On target",
                insight = p.notes.firstOrNull()
            )
        }

        PfraProfileCard(profile) { next -> container.pfraProfileStore.update { next } }
        PfraBodyCompositionCard(
            profile = profile,
            score = null,
            onChange = { next -> container.pfraProfileStore.update { next } },
            goalInline = {
                val target = componentTarget("Body Composition")
                if (target != null) PfraComponentGoalInline(target)
            }
        )
        PfraCardioCard(
            profile = profile,
            score = null,
            onChange = { next -> container.pfraProfileStore.update { next } },
            goalInline = {
                val target = componentTarget("Cardio")
                if (target != null) PfraComponentGoalInline(target)
            }
        )
        PfraStrengthCard(
            profile = profile,
            score = null,
            onChange = { next -> container.pfraProfileStore.update { next } },
            goalInline = {
                val target = componentTarget("Strength")
                if (target != null) PfraComponentGoalInline(target)
            }
        )
        PfraCoreCard(
            profile = profile,
            score = null,
            onChange = { next -> container.pfraProfileStore.update { next } },
            goalInline = {
                val target = componentTarget("Core")
                if (target != null) PfraComponentGoalInline(target)
            }
        )

        Button(
            onClick = { showSave = true },
            enabled = assessment != null
        ) { Text("Save record") }

        PfraDisclaimerCard(goalsMode = true)
        }
    }

    if (showSave && assessment != null) {
        PfraSaveDialog(
            saveKind = PFRARecordKind.GOAL_PLANNING,
            saveNote = saveNote,
            onKindChange = {},
            onNoteChange = { saveNote = it },
            onDismiss = { showSave = false },
            onConfirm = {
                scope.launch {
                    container.database.pfraDao().upsert(
                        assessment.toEntity(profile, PFRARecordKind.GOAL_PLANNING, saveNote.ifBlank { null })
                    )
                    showSave = false
                    saveNote = ""
                }
            }
        )
    }
}

private fun tierSubtitle(tier: PFRATargetTier): String = tier.subtitle
