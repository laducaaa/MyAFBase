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
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.ryanladuca.myafbase.domain.logic.LeaveDateUtils
import com.ryanladuca.myafbase.domain.logic.LeavePlanner
import com.ryanladuca.myafbase.domain.logic.LeavePlannedTrip
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.components.KeyValueRow
import com.ryanladuca.myafbase.ui.components.SectionCard
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

private enum class LeaveMode(val title: String) {
    TRIPS("Planned trips"),
    BY_DATE("By date"),
    PCS("PCS planning"),
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeavePlannerScreen(contentPadding: PaddingValues) {
    var mode by remember { mutableStateOf(LeaveMode.TRIPS) }
    var modeExpanded by remember { mutableStateOf(false) }
    var balanceText by remember { mutableStateOf("20") }
    var accrualText by remember { mutableStateOf("2.5") }
    var maxAccruingText by remember { mutableStateOf("60") }
    var maxPcsCapText by remember { mutableStateOf("60") }
    var specialLeaveText by remember { mutableStateOf("0") }
    var specialLeaveExpires by remember { mutableStateOf<Long?>(null) }
    var trips by remember {
        mutableStateOf(
            listOf(
                LeavePlannedTrip(
                    UUID.randomUUID().toString(),
                    "Trip 1",
                    System.currentTimeMillis() + 30L * 86400000,
                    System.currentTimeMillis() + 37L * 86400000,
                ),
            ),
        )
    }
    var targetDate by remember { mutableStateOf(System.currentTimeMillis() + 90L * 86400000) }
    var pcsDate by remember { mutableStateOf(System.currentTimeMillis() + 180L * 86400000) }
    var picking by remember { mutableStateOf<String?>(null) }
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.US) }
    val balance = balanceText.toDoubleOrNull() ?: 0.0
    val accrual = accrualText.toDoubleOrNull() ?: LeavePlanner.DEFAULT_ACCRUAL_PER_MONTH
    val maxAccruing = maxAccruingText.toDoubleOrNull() ?: LeavePlanner.DEFAULT_MAX_ACCRUING_BALANCE
    val maxPcsCap = maxPcsCapText.toDoubleOrNull() ?: LeavePlanner.DEFAULT_MAX_BALANCE_AT_PCS
    val specialLeave = specialLeaveText.toDoubleOrNull() ?: 0.0

    M3FlatScreenBackground {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding)
                .padding(AppTokens.screenPadding)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            ExposedDropdownMenuBox(
                expanded = modeExpanded,
                onExpandedChange = { modeExpanded = it },
            ) {
                OutlinedTextField(
                    value = mode.title,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("What kind of leave do you want to take?") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = modeExpanded) },
                    modifier = Modifier
                        .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                        .fillMaxWidth(),
                    shape = AppTextFieldDefaults.shape,
                    colors = AppTextFieldDefaults.colors(),
                )
                ExposedDropdownMenu(
                    expanded = modeExpanded,
                    onDismissRequest = { modeExpanded = false },
                ) {
                    LeaveMode.entries.forEach { m ->
                        DropdownMenuItem(
                            text = { Text(m.title) },
                            onClick = {
                                mode = m
                                modeExpanded = false
                            },
                        )
                    }
                }
            }

            Text(
                when (mode) {
                    LeaveMode.TRIPS -> "Plan multiple trips in sequence and see if accrual keeps up."
                    LeaveMode.BY_DATE -> "Project how much leave you'll have on a target date."
                    LeaveMode.PCS -> "Pace leave usage before PCS and watch fiscal-year carryover."
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            OutlinedTextField(
                balanceText,
                { balanceText = it },
                label = { Text("Current leave balance") },
                modifier = Modifier.fillMaxWidth(),
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            OutlinedTextField(
                accrualText,
                { accrualText = it },
                label = { Text("Accrual per month") },
                modifier = Modifier.fillMaxWidth(),
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            if (mode != LeaveMode.PCS) {
                OutlinedTextField(
                    maxAccruingText,
                    { maxAccruingText = it },
                    label = { Text("Max accruing balance") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = AppTextFieldDefaults.shape,
                    colors = AppTextFieldDefaults.colors(),
                )
            }

            // Results near top (after shared balance fields)
            when (mode) {
                LeaveMode.TRIPS -> {
                    LeavePlanner.evaluateMultipleTrips(balance, trips, accrual, maxAccruing)?.let { result ->
                        SectionCard(
                            title = if (result.allCovered) "All trips covered" else "Coverage gaps",
                            subtitle = "${"%.0f".format(result.totalLeaveDays)} leave days · final ${"%.1f".format(result.finalBalance)}",
                        ) {
                            result.evaluations.forEach {
                                KeyValueRow(
                                    it.trip.label.ifBlank { "Trip" },
                                    "${"%.0f".format(it.leaveDays)}d · start ${"%.1f".format(it.balanceBefore)} · " +
                                        if (it.isCovered) "OK" else "SHORT ${"%.1f".format(it.shortfall)}",
                                )
                            }
                            result.firstFailure?.let {
                                Text("First gap: ${it.trip.label}", style = MaterialTheme.typography.bodySmall)
                            }
                            result.overlapWarnings.forEach {
                                Text(it, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
                LeaveMode.BY_DATE -> {
                    LeavePlanner.projectBalance(balance, targetDate, accrual, maxAccruing)?.let { p ->
                        if (p.daysUntilTarget < 0) {
                            SectionCard(title = "Past date") {
                                Text("Target date is in the past. Pick a future date to project accrual.")
                            }
                        } else {
                            SectionCard(title = "Projection") {
                                KeyValueRow("Projected balance", "%.1f".format(p.projectedBalance))
                                KeyValueRow("Accrued", "%.1f".format(p.accruedAmount))
                                KeyValueRow("Days until", p.daysUntilTarget.toString())
                                if (p.hitAccrualCap) Text("Hits accrual cap before this date.")
                            }
                        }
                    }
                }
                LeaveMode.PCS -> {
                    LeavePlanner.plan(
                        currentBalance = balance,
                        pcsDateMillis = pcsDate,
                        maxBalanceAtPcs = maxPcsCap,
                        specialLeaveBalance = specialLeave,
                        specialLeaveExpiresMillis = specialLeaveExpires,
                    )?.let { plan ->
                        SectionCard(
                            title = if (plan.needsUsagePlan) "Usage pace needed" else "Under PCS cap",
                            subtitle = "${plan.daysUntilPcs} days until PCS",
                        ) {
                            if (plan.needsUsagePlan) {
                                KeyValueRow("Per month", "%.1f".format(plan.daysPerMonthToUse))
                                KeyValueRow("Per week", "%.1f".format(plan.daysPerWeekToUse))
                                KeyValueRow("Excess to burn", "%.1f".format(plan.excessLeave))
                            }
                            plan.milestones.forEach { m ->
                                KeyValueRow(dateFormat.format(Date(m.dateMillis)), m.title)
                            }
                            plan.notes.forEach {
                                Text(it, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }

            when (mode) {
                LeaveMode.TRIPS -> {
                    trips.forEachIndexed { index, trip ->
                        SectionCard(title = trip.label.ifBlank { "Trip ${index + 1}" }) {
                            OutlinedTextField(
                                trip.label,
                                { label ->
                                    trips = trips.toMutableList().also { it[index] = it[index].copy(label = label) }
                                },
                                label = { Text("Trip label") },
                                modifier = Modifier.fillMaxWidth(),
                                shape = AppTextFieldDefaults.shape,
                                colors = AppTextFieldDefaults.colors(),
                            )
                            OutlinedButton(
                                onClick = { picking = "trip-start-$index" },
                                modifier = Modifier.fillMaxWidth(),
                                colors = AppButtonDefaults.outlined(),
                            ) {
                                Text("Start: ${dateFormat.format(Date(trip.startMillis))}")
                            }
                            OutlinedButton(
                                onClick = { picking = "trip-end-$index" },
                                modifier = Modifier.fillMaxWidth(),
                                colors = AppButtonDefaults.outlined(),
                            ) {
                                Text("End: ${dateFormat.format(Date(trip.endMillis))}")
                            }
                            if (trips.size > 1) {
                                TextButton(onClick = { trips = trips.filterIndexed { i, _ -> i != index } }) {
                                    Text("Remove")
                                }
                            }
                        }
                    }
                    Button(
                        onClick = {
                            val start = System.currentTimeMillis() + (trips.size + 1) * 40L * 86400000
                            trips = trips + LeavePlannedTrip(
                                UUID.randomUUID().toString(),
                                "Trip ${trips.size + 1}",
                                start,
                                start + 5L * 86400000,
                            )
                        },
                        colors = AppButtonDefaults.primary(),
                    ) { Text("Add trip") }
                }
                LeaveMode.BY_DATE -> {
                    OutlinedButton(
                        onClick = { picking = "target" },
                        modifier = Modifier.fillMaxWidth(),
                        colors = AppButtonDefaults.outlined(),
                    ) {
                        Text("Target date: ${dateFormat.format(Date(targetDate))}")
                    }
                }
                LeaveMode.PCS -> {
                    OutlinedTextField(
                        maxPcsCapText,
                        { maxPcsCapText = it },
                        label = { Text("Max balance at PCS") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = AppTextFieldDefaults.shape,
                        colors = AppTextFieldDefaults.colors(),
                    )
                    OutlinedTextField(
                        specialLeaveText,
                        { specialLeaveText = it },
                        label = { Text("Special leave balance") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = AppTextFieldDefaults.shape,
                        colors = AppTextFieldDefaults.colors(),
                    )
                    OutlinedButton(
                        onClick = { picking = "special-exp" },
                        modifier = Modifier.fillMaxWidth(),
                        colors = AppButtonDefaults.outlined(),
                    ) {
                        Text(
                            specialLeaveExpires?.let { "Special leave expires: ${dateFormat.format(Date(it))}" }
                                ?: "Special leave expiration (optional)",
                        )
                    }
                    OutlinedButton(
                        onClick = { picking = "pcs" },
                        modifier = Modifier.fillMaxWidth(),
                        colors = AppButtonDefaults.outlined(),
                    ) {
                        Text("PCS date: ${dateFormat.format(Date(pcsDate))}")
                    }
                }
            }

            Text(
                "Unofficial estimate — confirm balances and caps with your unit CSS.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }

    val field = picking
    if (field != null) {
        val initial = when {
            field == "target" -> LeaveDateUtils.toDatePickerMillis(targetDate)
            field == "pcs" -> LeaveDateUtils.toDatePickerMillis(pcsDate)
            field == "special-exp" -> LeaveDateUtils.toDatePickerMillis(specialLeaveExpires ?: System.currentTimeMillis())
            field.startsWith("trip-start-") -> LeaveDateUtils.toDatePickerMillis(
                trips[field.removePrefix("trip-start-").toInt()].startMillis,
            )
            field.startsWith("trip-end-") -> LeaveDateUtils.toDatePickerMillis(
                trips[field.removePrefix("trip-end-").toInt()].endMillis,
            )
            else -> LeaveDateUtils.toDatePickerMillis(System.currentTimeMillis())
        }
        val state = rememberDatePickerState(initialSelectedDateMillis = initial)
        DatePickerDialog(
            onDismissRequest = { picking = null },
            confirmButton = {
                TextButton(onClick = {
                    val pickerMillis = state.selectedDateMillis ?: return@TextButton
                    val millis = LeaveDateUtils.fromDatePickerMillis(pickerMillis)
                    when {
                        field == "target" -> targetDate = millis
                        field == "pcs" -> pcsDate = millis
                        field == "special-exp" -> specialLeaveExpires = millis
                        field.startsWith("trip-start-") -> {
                            val i = field.removePrefix("trip-start-").toInt()
                            trips = trips.toMutableList().also {
                                it[i] = it[i].copy(startMillis = millis)
                            }
                        }
                        field.startsWith("trip-end-") -> {
                            val i = field.removePrefix("trip-end-").toInt()
                            trips = trips.toMutableList().also {
                                it[i] = it[i].copy(endMillis = millis)
                            }
                        }
                    }
                    picking = null
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { picking = null }) { Text("Cancel") } },
        ) { DatePicker(state = state) }
    }
}
