package com.ryanladuca.myafbase.ui.assignment

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.AssignmentProfileEntity
import com.ryanladuca.myafbase.data.db.ChecklistCompletionEntity
import com.ryanladuca.myafbase.data.db.ReadinessEntity
import com.ryanladuca.myafbase.domain.logic.PCSChecklist
import com.ryanladuca.myafbase.domain.logic.PCSChecklistKind
import com.ryanladuca.myafbase.domain.model.AssignmentSegment
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.EmptyBasePrompt
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AssignmentScreen(
    onPickBase: () -> Unit,
    onOpenLeavePlanner: () -> Unit = {},
    onOpenPfraGoals: () -> Unit = {},
    onOpenPfraScore: () -> Unit = {},
    contentPadding: PaddingValues
) {
    val appState = LocalAppState.current
    val container = LocalAppContainer.current
    val context = LocalContext.current
    val baseState by appState.currentBase.collectAsState()
    val scope = rememberCoroutineScope()
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.US) }

    val base = baseState
    if (base == null) {
        EmptyBasePrompt(onPickBase = onPickBase, contentPadding = contentPadding)
        return
    }

    val profile by container.database.assignmentDao().observe(base.id).collectAsState(initial = null)
    val readiness by container.database.readinessDao().observe(base.id).collectAsState(initial = null)
    val phase = AssignmentSegment.fromRaw(profile?.phaseRaw)
    val checklistKind = when (phase) {
        AssignmentSegment.INBOUND -> PCSChecklistKind.INBOUND
        AssignmentSegment.OUTBOUND -> PCSChecklistKind.OUTBOUND
        AssignmentSegment.STATIONED -> null
    }
    val completions = if (checklistKind != null) {
        container.database.checklistDao().observe(base.id, checklistKind.raw)
            .collectAsState(initial = emptyList()).value
    } else emptyList()
    val completedIds = completions.filter { it.completed }.map { it.itemId }.toSet()
    var dateField by remember { mutableStateOf<String?>(null) }
    var selectedSection by remember { mutableStateOf<com.ryanladuca.myafbase.domain.model.NewcomerSection?>(null) }
    var showPrimaryAction by remember { mutableStateOf(false) }

    fun saveDate(field: String, millis: Long?) {
        scope.launch {
            val current = container.database.assignmentDao().get(base.id)
            container.database.assignmentDao().upsert(
                AssignmentProfileEntity(
                    baseId = base.id,
                    phaseRaw = current?.phaseRaw ?: AssignmentSegment.STATIONED.raw,
                    reportDateMillis = if (field == "report") millis else current?.reportDateMillis,
                    pcsDateMillis = if (field == "pcs") millis else current?.pcsDateMillis,
                    updatedAtMillis = System.currentTimeMillis()
                )
            )
        }
    }

    fun saveReadiness(field: String, millis: Long?) {
        scope.launch {
            val current = readiness
            container.database.readinessDao().upsert(
                ReadinessEntity(
                    baseId = base.id,
                    fitnessTestDueMillis = if (field == "fitness") millis else current?.fitnessTestDueMillis,
                    dentalDueMillis = if (field == "dental") millis else current?.dentalDueMillis,
                    evalCloseoutDueMillis = if (field == "eval") millis else current?.evalCloseoutDueMillis,
                    pcsWindowStartMillis = current?.pcsWindowStartMillis,
                    pcsWindowEndMillis = current?.pcsWindowEndMillis,
                    cacExpirationMillis = if (field == "cac") millis else current?.cacExpirationMillis,
                    clearanceRenewalMillis = if (field == "clearance") millis else current?.clearanceRenewalMillis,
                    updatedAtMillis = System.currentTimeMillis()
                )
            )
            appState.refreshNotifications(context)
            appState.syncWidgets()
        }
    }

    M3FlatScreenBackground {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(contentPadding),
            contentPadding = PaddingValues(AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
        item { AssignmentPhaseHeader(base, phase) }
        item { AssignmentPhaseTipBanner() }
        item {
            AssignmentDatesCard(
                phase = phase,
                reportMillis = profile?.reportDateMillis,
                pcsMillis = profile?.pcsDateMillis,
                dateFormat = dateFormat,
                onPickReport = { dateField = "report" },
                onPickPcs = { dateField = "pcs" }
            )
        }

        when (phase) {
            AssignmentSegment.INBOUND -> {
                if (checklistKind != null) {
                    item {
                        val total = PCSChecklist.items(checklistKind).size
                        AssignmentChecklistCard(
                            title = checklistKind.title,
                            subtitle = "${completedIds.size}/$total complete · ${checklistKind.footer}",
                        )
                    }
                    item {
                        AssignmentChecklistGroup(
                            items = PCSChecklist.items(checklistKind),
                            completedIds = completedIds,
                            onToggle = { itemId, checked ->
                                scope.launch {
                                    if (checked) {
                                        container.database.checklistDao().upsert(
                                            ChecklistCompletionEntity(base.id, checklistKind.raw, itemId, true),
                                        )
                                    } else {
                                        container.database.checklistDao()
                                            .delete(base.id, checklistKind.raw, itemId)
                                    }
                                }
                            },
                        )
                    }
                }
                item {
                    Button(
                        onClick = {
                            val primary = base.newcomers.primaryAction
                            if (primary != null) {
                                showPrimaryAction = true
                            } else {
                                val uri = Uri.parse(
                                    "geo:${base.latitude},${base.longitude}?q=${base.latitude},${base.longitude}(${Uri.encode(base.name)})"
                                )
                                context.startActivity(Intent(Intent.ACTION_VIEW, uri))
                            }
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(base.newcomers.primaryAction?.title ?: "Report & arrive")
                    }
                }
                base.newcomers.moreInfoURL?.let { url ->
                    item {
                        TextButton(
                            onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) },
                            colors = AppButtonDefaults.text(),
                        ) { Text("Official newcomer information") }
                    }
                }
                item {
                    AssignmentSectionCard(title = "In-processing guides") {
                        base.newcomers.sections.forEach { section ->
                            TextButton(onClick = { selectedSection = section }) { Text(section.title) }
                        }
                        if (base.newcomers.sections.isEmpty()) {
                            Text("No newcomer sections for this base yet.")
                        }
                    }
                }
            }
            AssignmentSegment.STATIONED -> {
                item {
                    ReadinessTrackerSection(
                        readiness = readiness,
                        dateFormat = dateFormat,
                        onPickField = { dateField = it }
                    )
                }
                item {
                    AssignmentToolLinksCard(
                        onLeavePlanner = onOpenLeavePlanner,
                        onPfraGoals = onOpenPfraGoals,
                        onPfraScore = onOpenPfraScore,
                    )
                }
            }
            AssignmentSegment.OUTBOUND -> {
                item {
                    AssignmentToolLinksCard(
                        onLeavePlanner = onOpenLeavePlanner,
                        onPfraGoals = onOpenPfraGoals,
                        onPfraScore = onOpenPfraScore,
                    )
                }
                if (checklistKind != null) {
                    item {
                        AssignmentChecklistCard(
                            title = checklistKind.title,
                            subtitle = checklistKind.footer,
                        )
                    }
                    item {
                        AssignmentChecklistGroup(
                            items = PCSChecklist.items(checklistKind),
                            completedIds = completedIds,
                            onToggle = { itemId, checked ->
                                scope.launch {
                                    if (checked) {
                                        container.database.checklistDao().upsert(
                                            ChecklistCompletionEntity(base.id, checklistKind.raw, itemId, true),
                                        )
                                    } else {
                                        container.database.checklistDao()
                                            .delete(base.id, checklistKind.raw, itemId)
                                    }
                                }
                            },
                        )
                    }
                }
                item { OutboundLocationsCard(commonOutboundLocations) }
                item { AssignmentNextBaseCard(onChangeBase = onPickBase) }
            }
        }

        item {
            base.dataUpdatedAt?.let {
                Text(
                    "Base data updated $it",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
    }

    selectedSection?.let { section ->
        NewcomerSectionSheet(section = section, onDismiss = { selectedSection = null })
    }

    if (showPrimaryAction) {
        base.newcomers.primaryAction?.let { action ->
            NewcomerPrimaryActionSheet(
                action = action,
                baseName = base.name,
                latitude = base.latitude,
                longitude = base.longitude,
                onDismiss = { showPrimaryAction = false },
            )
        } ?: run { showPrimaryAction = false }
    }

    val field = dateField
    if (field != null) {
        val state = rememberDatePickerState()
        DatePickerDialog(
            onDismissRequest = { dateField = null },
            confirmButton = {
                TextButton(onClick = {
                    val millis = state.selectedDateMillis
                    when (field) {
                        "report", "pcs" -> saveDate(field, millis)
                        else -> saveReadiness(field, millis)
                    }
                    dateField = null
                }) { Text("Save") }
            },
            dismissButton = {
                TextButton(onClick = { dateField = null }) { Text("Cancel") }
            }
        ) {
            DatePicker(state = state)
        }
    }
}
