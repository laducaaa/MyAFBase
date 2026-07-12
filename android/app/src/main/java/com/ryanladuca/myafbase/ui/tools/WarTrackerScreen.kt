package com.ryanladuca.myafbase.ui.tools

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import android.widget.Toast
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.ryanladuca.myafbase.data.db.WarAwardDeadlineEntity
import com.ryanladuca.myafbase.data.db.WarEntryEntity
import com.ryanladuca.myafbase.domain.logic.WarDateMath
import com.ryanladuca.myafbase.domain.logic.WarRetentionService
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.components.KeyValueRow
import com.ryanladuca.myafbase.ui.components.SectionCard
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import java.util.concurrent.TimeUnit

private enum class WarPanel { LOG, DEADLINES, REPORTS, SETTINGS }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WarTrackerScreen(contentPadding: PaddingValues) {
    val context = LocalContext.current
    val container = LocalAppContainer.current
    val appState = LocalAppState.current
    val base by appState.currentBase.collectAsState()
    val baseId = base?.id.orEmpty()
    val scope = rememberCoroutineScope()
    var unlocked by remember { mutableStateOf(false) }
    var panel by remember { mutableStateOf(WarPanel.LOG) }
    var weekOffset by remember { mutableStateOf(0) }
    var quickAddContext by remember { mutableStateOf<WarQuickAddContext?>(null) }
    val dateFormat = remember { SimpleDateFormat("EEE, MMM d", Locale.US) }

    val entries by container.database.warDao().observeForBase(baseId)
        .collectAsState(initial = emptyList())
    val deadlines by container.database.warAwardDeadlineDao().observeForBase(baseId)
        .collectAsState(initial = emptyList())
    val readiness by container.database.readinessDao().observe(baseId)
        .collectAsState(initial = null)

    LaunchedEffect(Unit) {
        if (!container.preferences.warLocked.first()) unlocked = true
        val prefs = container.preferences.warNotificationSettings()
        WarRetentionService.purgeExpiredEntries(
            entries = container.database.warDao().observeAll().first(),
            autoDeleteEnabled = prefs.autoDeleteEnabled,
            autoDeleteAfterYears = prefs.autoDeleteAfterYears,
        ) { id -> container.database.warDao().delete(id) }
    }

    if (!unlocked) {
        M3FlatScreenBackground {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(contentPadding)
                    .padding(AppTokens.screenPadding),
                verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
            ) {
            Text("WAR Tracker locked", style = MaterialTheme.typography.headlineSmall)
            Text("Unlock with biometrics to view your personal accomplishment log.")
            Button(onClick = {
                val activity = context as? FragmentActivity
                if (activity == null) {
                    unlocked = true
                    return@Button
                }
                val prompt = BiometricPrompt(
                    activity,
                    ContextCompat.getMainExecutor(context),
                    object : BiometricPrompt.AuthenticationCallback() {
                        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                            unlocked = true
                        }
                    }
                )
                if (BiometricManager.from(context)
                        .canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)
                    == BiometricManager.BIOMETRIC_SUCCESS
                ) {
                    prompt.authenticate(
                        BiometricPrompt.PromptInfo.Builder()
                            .setTitle("Unlock WAR Tracker")
                            .setNegativeButtonText("Cancel")
                            .build()
                    )
                } else unlocked = true
            }) { Text("Unlock") }
            TextButton(onClick = {
                scope.launch { container.preferences.setWarLocked(false) }
                unlocked = true
            }) { Text("Disable lock") }
            }
        }
        return
    }

    val weekStart = remember(weekOffset) {
        val today = WarDateMath.startOfDay(System.currentTimeMillis())
        val calStart = WarDateMath.startOfWeek(today)
        WarDateMath.addDays(calStart, weekOffset * 7)
    }
    val weekDays = remember(weekStart) { WarDateMath.weekDays(weekStart) }
    val weekEntries = entries.filter { entry ->
        weekDays.any { day ->
            val dayStart = WarDateMath.startOfDay(day)
            val dayEnd = dayStart + 86_399_999L
            entry.dateMillis in dayStart..dayEnd
        }
    }
    val byDay = weekDays.map { day ->
        val dayStart = WarDateMath.startOfDay(day)
        val dayEnd = dayStart + 86_399_999L
        dayStart to weekEntries.filter { it.dateMillis in dayStart..dayEnd }
    }

    M3FlatScreenBackground {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(contentPadding),
        contentPadding = PaddingValues(AppTokens.screenPadding),
        verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)
    ) {
        item {
            Text(
                "Unofficial personal log for ${base?.name ?: "this device"}. Avoid PII and CUI.",
                style = MaterialTheme.typography.bodySmall
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                WarPanel.entries.forEach { p ->
                    FilterChip(
                        selected = panel == p,
                        onClick = { panel = p },
                        label = { Text(p.name.lowercase().replaceFirstChar { it.uppercase() }) },
                        colors = AppChipDefaults.filterChip(selected = panel == p),
                    )
                }
            }
        }

        when (panel) {
            WarPanel.LOG -> {
                item {
                    Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                        TextButton(onClick = { weekOffset-- }) { Text("Prev week") }
                        Text(dateFormat.format(Date(weekStart)))
                        TextButton(onClick = { weekOffset++ }) { Text("Next week") }
                    }
                    Button(onClick = {
                        quickAddContext = WarQuickAddContext(
                            dateMillis = WarDateMath.startOfDay(System.currentTimeMillis()),
                            locksDate = false
                        )
                    }) { Text("Add entry") }
                }
                byDay.forEach { (day, dayEntries) ->
                    val isEmpty = dayEntries.isEmpty()
                    item {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                        ) {
                            Column(
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable(enabled = isEmpty) {
                                        quickAddContext = WarQuickAddContext(day, locksDate = true)
                                    }
                            ) {
                                Text(
                                    WarDateMath.dayLabel(day),
                                    style = MaterialTheme.typography.titleSmall
                                )
                                Text(
                                    if (isEmpty) "Nothing logged" else "${dayEntries.size} entries",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            IconButton(onClick = {
                                quickAddContext = WarQuickAddContext(day, locksDate = true)
                            }) {
                                Icon(Icons.Default.Add, contentDescription = "Add for this day")
                            }
                        }
                    }
                    if (isEmpty) {
                        item {
                            Text("Tap the day or + to log for this date.", style = MaterialTheme.typography.bodySmall)
                        }
                    } else {
                        items(dayEntries, key = { it.id }) { entry ->
                            SectionCard(
                                title = entry.title,
                                subtitle = "${entry.category} · ${entry.hours}h",
                                onClick = {
                                    quickAddContext = WarQuickAddContext(
                                        dateMillis = entry.dateMillis,
                                        locksDate = false,
                                        entryToEdit = entry
                                    )
                                }
                            ) {
                                Text(entry.body)
                                if (entry.impact.isNotBlank()) Text("Impact: ${entry.impact}")
                                if (entry.tags.isNotBlank()) Text("Tags: ${entry.tags}")
                                TextButton(onClick = {
                                    scope.launch {
                                        container.database.warDao().delete(entry.id)
                                        appState.syncWidgets()
                                    }
                                }) { Text("Delete") }
                            }
                        }
                    }
                }
            }
            WarPanel.DEADLINES -> {
                item {
                    var dTitle by remember { mutableStateOf("") }
                    var dDate by remember { mutableStateOf(System.currentTimeMillis() + 30L * 86400000) }
                    var pick by remember { mutableStateOf(false) }
                    SectionCard(title = "Add award deadline") {
                        OutlinedTextField(dTitle, { dTitle = it }, label = { Text("Title") }, modifier = Modifier.fillMaxWidth(),
            shape = AppTextFieldDefaults.shape,
            colors = AppTextFieldDefaults.colors(),
        )
                        TextButton(onClick = { pick = true }) {
                            Text("Due: ${dateFormat.format(Date(dDate))}")
                        }
                        Button(onClick = {
                            if (dTitle.isBlank() || baseId.isBlank()) return@Button
                            scope.launch {
                                container.database.warAwardDeadlineDao().upsert(
                                    WarAwardDeadlineEntity(
                                        id = UUID.randomUUID().toString(),
                                        baseId = baseId,
                                        title = dTitle.trim(),
                                        deadlineMillis = dDate
                                    )
                                )
                                appState.refreshNotifications(context)
                                dTitle = ""
                            }
                        }) { Text("Save deadline") }
                    }
                    if (pick) {
                        val state = rememberDatePickerState(initialSelectedDateMillis = dDate)
                        DatePickerDialog(
                            onDismissRequest = { pick = false },
                            confirmButton = {
                                TextButton(onClick = {
                                    state.selectedDateMillis?.let { dDate = it }
                                    pick = false
                                }) { Text("OK") }
                            },
                            dismissButton = { TextButton(onClick = { pick = false }) { Text("Cancel") } }
                        ) { DatePicker(state = state) }
                    }
                }
                items(deadlines, key = { it.id }) { d ->
                    SectionCard(
                        title = d.title,
                        subtitle = "Due ${dateFormat.format(Date(d.deadlineMillis))} · in ${
                            TimeUnit.MILLISECONDS.toDays(d.deadlineMillis - System.currentTimeMillis())
                        } days"
                    ) {
                        TextButton(onClick = {
                            scope.launch {
                                container.database.warAwardDeadlineDao().delete(d.id)
                                appState.refreshNotifications(context)
                            }
                        }) { Text("Delete") }
                    }
                }
            }
            WarPanel.REPORTS -> {
                item {
                    WarReportsPanel(
                        entries = entries,
                        readiness = readiness,
                        baseName = base?.name,
                        onExportPdf = { exportWarPdf(context, it) },
                    )
                }
            }
            WarPanel.SETTINGS -> {
                item {
                    WarSettingsPanel(
                        onLockEnabled = {
                            scope.launch { container.preferences.setWarLocked(true) }
                            unlocked = false
                        },
                        onLockDisabled = {
                            scope.launch { container.preferences.setWarLocked(false) }
                        },
                    )
                }
            }
        }
    }
    }

    quickAddContext?.let { ctx ->
        WarQuickAddSheet(
            context = ctx.copy(
                entryToEdit = ctx.entryToEdit?.copy(baseId = baseId),
                dateMillis = ctx.entryToEdit?.dateMillis ?: ctx.dateMillis
            ),
            onDismiss = { quickAddContext = null },
            onSave = { entry ->
                scope.launch {
                    container.database.warDao().upsert(entry.copy(baseId = baseId))
                    appState.refreshNotifications(context)
                    appState.syncWidgets()
                    quickAddContext = null
                }
            }
        )
    }
}

private fun exportWarPdf(context: Context, entries: List<WarEntryEntity>) {
    val doc = PdfDocument()
    var pageNumber = 1
    var page = doc.startPage(PdfDocument.PageInfo.Builder(595, 842, pageNumber).create())
    var canvas = page.canvas
    val paint = Paint().apply { textSize = 11f }
    var y = 40f
    fun newPage() {
        doc.finishPage(page)
        pageNumber++
        page = doc.startPage(PdfDocument.PageInfo.Builder(595, 842, pageNumber).create())
        canvas = page.canvas
        y = 40f
    }
    canvas.drawText("MyAFBase WAR Tracker Export", 40f, y, paint)
    y += 24f
    entries.forEach { entry ->
        if (y > 780) newPage()
        canvas.drawText(entry.title, 40f, y, paint)
        y += 16f
        entry.body.chunked(85).forEach { line ->
            if (y > 800) newPage()
            canvas.drawText(line, 40f, y, paint)
            y += 14f
        }
        y += 10f
    }
    doc.finishPage(page)
    val file = File(context.cacheDir, "war-export.pdf")
    FileOutputStream(file).use { doc.writeTo(it) }
    doc.close()
    Toast.makeText(context, "Saved ${file.name} to cache", Toast.LENGTH_LONG).show()
}
