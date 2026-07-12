package com.ryanladuca.myafbase.ui.tools

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.ryanladuca.myafbase.domain.logic.PFRARecordKind
import com.ryanladuca.myafbase.domain.logic.PFRAScoring
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch

@Composable
fun PfraScoreScreen(contentPadding: PaddingValues) {
    val container = LocalAppContainer.current
    val profile by container.pfraProfileStore.profile.collectAsState()
    val scope = rememberCoroutineScope()
    var showSave by remember { mutableStateOf(false) }
    var saveKind by remember { mutableStateOf(PFRARecordKind.DIAGNOSTIC) }
    var saveNote by remember { mutableStateOf("") }
    val snackbarHostState = remember { SnackbarHostState() }
    var showSavedToast by remember { mutableStateOf(false) }

    val assessment = remember(profile) { pfraAssessment(profile) }
    val update: (com.ryanladuca.myafbase.data.prefs.PFRAProfile) -> Unit = { next ->
        container.pfraProfileStore.update { next }
    }

    LaunchedEffect(showSavedToast) {
        if (showSavedToast) {
            snackbarHostState.showSnackbar("Score saved")
            showSavedToast = false
        }
    }

    M3FlatScreenBackground {
        Column(modifier = Modifier.fillMaxSize().padding(contentPadding)) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(AppTokens.screenPadding),
                verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
            ) {
                assessment?.let { result ->
                    PfraCompositeSummaryCard(
                        composite = result.compositeScore,
                        target = PFRAScoring.PASS_COMPOSITE,
                        passed = result.passed,
                        rating = result.rating,
                        verdictTitle = if (result.passed) "Passing estimate" else "Below pass threshold",
                        verdictSubtitle = "${result.rating} · ${"%.1f".format(result.compositeScore)} composite",
                        progressLabel = "To pass",
                        passingLabel = "Passing",
                        insight = result.guidance.firstOrNull(),
                    )
                }
                PfraProfileCard(profile, update)
                PfraBodyCompositionCard(profile, assessment?.let { componentScore(it, "Body Composition") }, update)
                PfraCardioCard(profile, assessment?.let { componentScore(it, "Cardio") }, update)
                PfraStrengthCard(profile, assessment?.let { componentScore(it, "Strength") }, update)
                PfraCoreCard(profile, assessment?.let { componentScore(it, "Core") }, update)
                Button(
                    onClick = { saveKind = PFRARecordKind.DIAGNOSTIC; showSave = true },
                    enabled = assessment != null,
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Save Score") }
                PfraDisclaimerCard(goalsMode = false)
            }
            SnackbarHost(hostState = snackbarHostState, modifier = Modifier.padding(AppTokens.screenPadding))
        }
    }

    if (showSave && assessment != null) {
        PfraSaveDialog(
            saveKind = saveKind,
            saveNote = saveNote,
            onKindChange = { saveKind = it },
            onNoteChange = { saveNote = it },
            onDismiss = { showSave = false },
            onConfirm = {
                scope.launch {
                    container.database.pfraDao().upsert(
                        assessment.toEntity(profile, saveKind, saveNote.ifBlank { null }),
                    )
                    showSave = false
                    saveNote = ""
                    showSavedToast = true
                }
            },
        )
    }
}
