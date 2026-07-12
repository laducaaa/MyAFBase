package com.ryanladuca.myafbase.ui.tools

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.WarEntryEntity
import com.ryanladuca.myafbase.domain.logic.LeaveDateUtils
import com.ryanladuca.myafbase.domain.logic.WarDateMath
import com.ryanladuca.myafbase.ui.components.SheetDragHandle
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens

data class WarQuickAddContext(
    val dateMillis: Long,
    val locksDate: Boolean,
    val entryToEdit: WarEntryEntity? = null,
    val prefillBody: String? = null,
)

private val piiPatterns = listOf(
    Regex("\\b\\d{3}-\\d{2}-\\d{4}\\b"),
    Regex("(?i)\\bssn\\b"),
    Regex("(?i)\\bclassified\\b"),
    Regex("(?i)\\bcui\\b")
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WarQuickAddSheet(
    context: WarQuickAddContext,
    onDismiss: () -> Unit,
    onSave: (WarEntryEntity) -> Unit
) {
    val editing = context.entryToEdit
    var dateMillis by remember(context) {
        mutableStateOf(WarDateMath.startOfDay(editing?.dateMillis ?: context.dateMillis))
    }
    var title by remember(editing) { mutableStateOf(editing?.title.orEmpty()) }
    var body by remember(editing, context.prefillBody) {
        mutableStateOf(editing?.body ?: context.prefillBody.orEmpty())
    }
    var category by remember(editing) { mutableStateOf(editing?.category ?: "mission") }
    var impact by remember(editing) { mutableStateOf(editing?.impact.orEmpty()) }
    var tags by remember(editing) { mutableStateOf(editing?.tags.orEmpty()) }
    var hours by remember(editing) { mutableStateOf(editing?.hours?.toString() ?: "0") }
    var piiWarning by remember { mutableStateOf<String?>(null) }
    var showDatePicker by remember { mutableStateOf(false) }

    val showLockedDate = context.locksDate && editing == null
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        dragHandle = { SheetDragHandle() },
        containerColor = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = AppTokens.screenPadding)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(AppTokens.innerCornerRadius),
        ) {
            Text(
                when {
                    editing != null -> "Edit entry"
                    showLockedDate -> WarDateMath.dayLabel(dateMillis)
                    else -> "Quick log"
                },
                style = MaterialTheme.typography.titleLarge,
            )
            if (!showLockedDate) {
                TextButton(
                    onClick = { showDatePicker = true },
                    colors = AppButtonDefaults.text(),
                ) {
                    Text("Date: ${WarDateMath.dayLabel(dateMillis)}")
                }
            }
            listOf("mission", "leadership", "training", "other").forEach { cat ->
                FilterChip(
                    selected = category == cat,
                    onClick = { category = cat },
                    label = { Text(cat) },
                    colors = AppChipDefaults.filterChip(selected = category == cat),
                )
            }
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Title") },
                modifier = Modifier.fillMaxWidth(),
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            OutlinedTextField(
                value = body,
                onValueChange = { body = it },
                label = { Text("Accomplishment") },
                modifier = Modifier.fillMaxWidth(),
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            OutlinedTextField(
                value = impact,
                onValueChange = { impact = it },
                label = { Text("Impact") },
                modifier = Modifier.fillMaxWidth(),
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            OutlinedTextField(
                value = tags,
                onValueChange = { tags = it },
                label = { Text("Tags") },
                modifier = Modifier.fillMaxWidth(),
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            OutlinedTextField(
                value = hours,
                onValueChange = { hours = it },
                label = { Text("Hours") },
                modifier = Modifier.fillMaxWidth(),
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            piiWarning?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            Button(
                onClick = {
                    val blob = "$title $body $impact $tags"
                    if (piiPatterns.any { it.containsMatchIn(blob) }) {
                        piiWarning = "Possible PII/sensitive terms detected. Remove them before saving."
                        return@Button
                    }
                    if (title.isBlank() || body.isBlank()) return@Button
                    onSave(
                        WarEntryEntity(
                            id = editing?.id ?: java.util.UUID.randomUUID().toString(),
                            baseId = editing?.baseId.orEmpty(),
                            dateMillis = WarDateMath.startOfDay(dateMillis),
                            title = title.trim(),
                            body = body.trim(),
                            category = category,
                            impact = impact.trim(),
                            tags = tags.trim(),
                            hours = hours.toDoubleOrNull() ?: 0.0
                        )
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                colors = AppButtonDefaults.primary(),
                shape = MaterialTheme.shapes.small,
            ) {
                Text(if (editing != null) "Update" else "Save")
            }
        }
    }

    if (showDatePicker) {
        val state = rememberDatePickerState(
            initialSelectedDateMillis = LeaveDateUtils.toDatePickerMillis(dateMillis)
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        state.selectedDateMillis?.let {
                            dateMillis = LeaveDateUtils.fromDatePickerMillis(it)
                        }
                        showDatePicker = false
                    },
                    colors = AppButtonDefaults.text(),
                ) { Text("OK") }
            },
            dismissButton = {
                TextButton(
                    onClick = { showDatePicker = false },
                    colors = AppButtonDefaults.textNeutral(),
                ) { Text("Cancel") }
            }
        ) { DatePicker(state = state) }
    }
}
