package com.ryanladuca.myafbase.ui.tools

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import com.ryanladuca.myafbase.data.db.ReadinessEntity
import com.ryanladuca.myafbase.data.db.WarEntryEntity
import com.ryanladuca.myafbase.domain.logic.WarDateRangePreset
import com.ryanladuca.myafbase.domain.logic.WarOutputBuilder
import com.ryanladuca.myafbase.domain.logic.WarOutputFormat
import com.ryanladuca.myafbase.domain.logic.WarOutputGrouping
import com.ryanladuca.myafbase.notifications.NotificationPermission
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.SectionCard
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WarReportsPanel(
    entries: List<WarEntryEntity>,
    readiness: ReadinessEntity?,
    baseName: String?,
    onExportPdf: (List<WarEntryEntity>) -> Unit,
) {
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.US) }
    var preset by remember { mutableStateOf(WarDateRangePreset.THIS_MONTH) }
    var customStart by remember { mutableStateOf(System.currentTimeMillis()) }
    var customEnd by remember { mutableStateOf(System.currentTimeMillis()) }
    var grouping by remember { mutableStateOf(WarOutputGrouping.CHRONOLOGICAL) }
    var format by remember { mutableStateOf(WarOutputFormat.PLAIN_TEXT) }
    var pickStart by remember { mutableStateOf(false) }
    var pickEnd by remember { mutableStateOf(false) }
    val context = LocalContext.current

    val range = WarOutputBuilder.dateRange(
        preset = preset,
        customStartMillis = customStart,
        customEndMillis = customEnd,
        evalCloseoutMillis = readiness?.evalCloseoutDueMillis,
    )
    val filtered = remember(entries, range) { WarOutputBuilder.entriesInRange(entries, range) }
    val summary = remember(filtered) { WarOutputBuilder.summary(filtered) }
    val outputText = remember(filtered, grouping, format) {
        WarOutputBuilder.build(filtered, grouping, format)
    }

    SectionCard(title = "Date range") {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            WarDateRangePreset.entries.forEach { item ->
                FilterChip(
                    selected = preset == item,
                    onClick = { preset = item },
                    label = { Text(item.title, style = MaterialTheme.typography.labelSmall) },
                )
            }
        }
        if (preset == WarDateRangePreset.CUSTOM) {
            TextButton(onClick = { pickStart = true }) {
                Text("Start: ${dateFormat.format(Date(customStart))}")
            }
            TextButton(onClick = { pickEnd = true }) {
                Text("End: ${dateFormat.format(Date(customEnd))}")
            }
        } else {
            Text(
                "${dateFormat.format(Date(range.first))} – ${dateFormat.format(Date(range.last))}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (preset == WarDateRangePreset.CLOSEOUT_CYCLE && readiness?.evalCloseoutDueMillis == null) {
            Text(
                "Set your EPB/OPB closeout date in Readiness to tailor this range.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }

    SectionCard(title = "Summary") {
        Text("${summary.totalEntries} entries · ${summary.totalHours.toInt()}h logged")
        summary.categoryCounts.forEach { (category, count) ->
            Text("$category: $count", style = MaterialTheme.typography.bodySmall)
        }
    }

    SectionCard(title = "Output options") {
        Text("Grouping", style = MaterialTheme.typography.labelMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            WarOutputGrouping.entries.forEach { item ->
                FilterChip(
                    selected = grouping == item,
                    onClick = { grouping = item },
                    label = { Text(item.title) },
                )
            }
        }
        Text("Format", style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(top = 8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            WarOutputFormat.entries.forEach { item ->
                FilterChip(
                    selected = format == item,
                    onClick = { format = item },
                    label = { Text(item.title) },
                )
            }
        }
        Text(format.helpText, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }

    SectionCard(title = "Preview (${filtered.size} entries)") {
        Text(outputText.take(1200) + if (outputText.length > 1200) "…" else "")
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TextButton(onClick = {
                val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cm.setPrimaryClip(ClipData.newPlainText("WAR Report", outputText))
                Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
            }) { Text("Copy text") }
            TextButton(onClick = { onExportPdf(filtered) }) { Text("Export PDF") }
        }
    }

    if (pickStart) {
        val state = rememberDatePickerState(initialSelectedDateMillis = customStart)
        DatePickerDialog(
            onDismissRequest = { pickStart = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let { customStart = it }
                    pickStart = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { pickStart = false }) { Text("Cancel") } },
        ) { DatePicker(state = state) }
    }
    if (pickEnd) {
        val state = rememberDatePickerState(initialSelectedDateMillis = customEnd)
        DatePickerDialog(
            onDismissRequest = { pickEnd = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let { customEnd = it }
                    pickEnd = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { pickEnd = false }) { Text("Cancel") } },
        ) { DatePicker(state = state) }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WarSettingsPanel(
    onLockEnabled: () -> Unit,
    onLockDisabled: () -> Unit,
) {
    val context = LocalContext.current
    val container = LocalAppContainer.current
    val appState = LocalAppState.current
    val scope = rememberCoroutineScope()
    var settings by remember { mutableStateOf(com.ryanladuca.myafbase.data.prefs.WarNotificationSettings()) }
    var permissionDenied by remember { mutableStateOf(false) }
    val warLocked by container.preferences.warLocked.collectAsState(initial = false)

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        appState.onNotificationPermissionResult(granted, context)
        permissionDenied = !granted
        if (granted) scope.launch { settings = container.preferences.warNotificationSettings() }
    }

    androidx.compose.runtime.LaunchedEffect(Unit) {
        settings = container.preferences.warNotificationSettings()
    }

    fun ensurePermission(onGranted: () -> Unit) {
        if (NotificationPermission.isGranted(context)) {
            onGranted()
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            onGranted()
        }
    }

    SectionCard(title = "Performance report") {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            com.ryanladuca.myafbase.domain.logic.WarMemberType.entries.forEach { type ->
                FilterChip(
                    selected = settings.memberType == type.name.lowercase(),
                    onClick = {
                        scope.launch {
                            container.preferences.setWarMemberType(type.name.lowercase())
                            settings = settings.copy(memberType = type.name.lowercase())
                        }
                    },
                    label = { Text(type.title) },
                )
            }
        }
    }

    SectionCard(title = "Reminders") {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        ) {
            Text("Daily log nudge")
            androidx.compose.material3.Switch(
                checked = settings.dailyNudgeEnabled,
                onCheckedChange = { enabled ->
                    ensurePermission {
                        scope.launch {
                            container.preferences.setWarDailyNudgeEnabled(enabled)
                            settings = settings.copy(dailyNudgeEnabled = enabled)
                            appState.refreshNotifications(context)
                        }
                    }
                },
            )
        }
        if (settings.dailyNudgeEnabled) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                OutlinedButton(onClick = {
                    scope.launch {
                        val hour = (settings.dailyNudgeHour - 1).coerceAtLeast(5)
                        container.preferences.setWarDailyNudgeHour(hour)
                        settings = settings.copy(dailyNudgeHour = hour)
                        appState.refreshNotifications(context)
                    }
                }) { Text("−") }
                Text("Remind at ${settings.dailyNudgeHour}:00")
                OutlinedButton(onClick = {
                    scope.launch {
                        val hour = (settings.dailyNudgeHour + 1).coerceAtMost(22)
                        container.preferences.setWarDailyNudgeHour(hour)
                        settings = settings.copy(dailyNudgeHour = hour)
                        appState.refreshNotifications(context)
                    }
                }) { Text("+") }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        ) {
            Text("Weekly WAR reminder")
            androidx.compose.material3.Switch(
                checked = settings.weeklyReminderEnabled,
                onCheckedChange = { enabled ->
                    ensurePermission {
                        scope.launch {
                            container.preferences.setWarWeeklyReminderEnabled(enabled)
                            settings = settings.copy(weeklyReminderEnabled = enabled)
                            appState.refreshNotifications(context)
                        }
                    }
                },
            )
        }
        if (permissionDenied) {
            Text(
                "Notifications are disabled for MyAFBase. Enable them in Settings to use reminders.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error,
            )
        }
    }

    SectionCard(title = "Privacy") {
        if (warLocked) {
            Button(onClick = onLockDisabled, modifier = Modifier.fillMaxWidth()) { Text("Disable biometric lock") }
        } else {
            Button(onClick = onLockEnabled, modifier = Modifier.fillMaxWidth()) { Text("Enable biometric lock") }
        }
        Text(
            "When enabled, WAR Tracker locks until you authenticate.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }

    SectionCard(title = "Retention") {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        ) {
            Text("Auto-delete old entries")
            androidx.compose.material3.Switch(
                checked = settings.autoDeleteEnabled,
                onCheckedChange = { enabled ->
                    scope.launch {
                        container.preferences.setWarAutoDeleteEnabled(enabled)
                        settings = settings.copy(autoDeleteEnabled = enabled)
                        if (enabled) purgeWarEntries(container)
                    }
                },
            )
        }
        if (settings.autoDeleteEnabled) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                OutlinedButton(onClick = {
                    scope.launch {
                        val years = (settings.autoDeleteAfterYears - 1).coerceAtLeast(1)
                        container.preferences.setWarAutoDeleteAfterYears(years)
                        settings = settings.copy(autoDeleteAfterYears = years)
                        purgeWarEntries(container)
                    }
                }) { Text("−") }
                Text("Keep ${settings.autoDeleteAfterYears} years")
                OutlinedButton(onClick = {
                    scope.launch {
                        val years = (settings.autoDeleteAfterYears + 1).coerceAtMost(10)
                        container.preferences.setWarAutoDeleteAfterYears(years)
                        settings = settings.copy(autoDeleteAfterYears = years)
                        purgeWarEntries(container)
                    }
                }) { Text("+") }
            }
        }
    }
}

private suspend fun purgeWarEntries(container: com.ryanladuca.myafbase.data.AppContainer) {
    val prefs = container.preferences.warNotificationSettings()
    val all = container.database.warDao().observeAll().first()
    com.ryanladuca.myafbase.domain.logic.WarRetentionService.purgeExpiredEntries(
        entries = all,
        autoDeleteEnabled = prefs.autoDeleteEnabled,
        autoDeleteAfterYears = prefs.autoDeleteAfterYears,
    ) { id -> container.database.warDao().delete(id) }
}
