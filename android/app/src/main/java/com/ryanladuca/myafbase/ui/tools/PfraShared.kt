package com.ryanladuca.myafbase.ui.tools

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.PfraRecordEntity
import com.ryanladuca.myafbase.data.prefs.PFRAProfile
import com.ryanladuca.myafbase.domain.logic.PFRARecordKind
import com.ryanladuca.myafbase.domain.logic.PFRAResult
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppDialogDefaults
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import java.util.UUID

@Composable
fun PfraSaveDialog(
    saveKind: PFRARecordKind,
    saveNote: String,
    onKindChange: (PFRARecordKind) -> Unit,
    onNoteChange: (String) -> Unit,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        shape = AppDialogDefaults.shape,
        containerColor = AppDialogDefaults.containerColor(),
        title = {
            Text(
                "Save PFRA record",
                style = MaterialTheme.typography.headlineSmall,
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                PFRARecordKind.entries.forEach { kind ->
                    FilterChip(
                        selected = saveKind == kind,
                        onClick = { onKindChange(kind) },
                        label = { Text(kind.title) },
                        colors = AppChipDefaults.filterChip(selected = saveKind == kind),
                    )
                }
                OutlinedTextField(
                    value = saveNote,
                    onValueChange = onNoteChange,
                    label = { Text("Note (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = AppTextFieldDefaults.shape,
                    colors = AppTextFieldDefaults.colors(),
                )
            }
        },
        confirmButton = {
            FilledTonalButton(
                onClick = onConfirm,
                colors = AppButtonDefaults.tonal(),
            ) { Text("Save") }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                colors = AppButtonDefaults.textNeutral(),
            ) { Text("Cancel") }
        },
    )
}

fun PFRAResult.toEntity(
    profile: PFRAProfile,
    kind: PFRARecordKind,
    note: String?
): PfraRecordEntity = PfraRecordEntity(
    id = UUID.randomUUID().toString(),
    dateMillis = System.currentTimeMillis(),
    score = compositeScore,
    rating = rating,
    passed = passed,
    kind = kind.name,
    note = note,
    targetTier = if (kind == PFRARecordKind.GOAL_PLANNING) profile.targetTier.name else null,
    detailsJson = componentScores.joinToString("|") { "${it.name}:${it.points}:${it.detail}" },
    gender = profile.gender.name,
    age = profile.age,
    heightInches = profile.heightTotalInches,
    waistInches = profile.waistInches,
    cardioEvent = profile.cardioEvent.name,
    cardioValue = profile.cardioValue,
    strengthEvent = profile.strengthEvent.name,
    strengthReps = profile.strengthReps,
    coreEvent = profile.coreEvent.name,
    coreValue = profile.coreValue
)
