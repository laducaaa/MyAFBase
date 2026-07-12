package com.ryanladuca.myafbase.ui.tools

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
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
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.SpecialPayEntity
import com.ryanladuca.myafbase.domain.logic.PayCalendar
import com.ryanladuca.myafbase.domain.logic.PayCalendarInsight
import com.ryanladuca.myafbase.domain.logic.PayInsightSeverity
import com.ryanladuca.myafbase.domain.logic.SpecialPayEntry
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.components.M3NestedSurface
import com.ryanladuca.myafbase.ui.components.M3SurfaceCard
import com.ryanladuca.myafbase.ui.theme.AppMotion
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.ui.theme.appSemanticColors
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PayCalendarScreen(
    contentPadding: PaddingValues,
    requestAdd: Boolean = false,
    onAddHandled: () -> Unit = {},
) {
    val container = LocalAppContainer.current
    val appState = LocalAppState.current
    val specials by container.database.specialPayDao().observeAll().collectAsState(initial = emptyList())
    val events = remember(specials) {
        PayCalendar.upcomingEvents(
            specialPays = specials.map { SpecialPayEntry(it.id, it.title, it.dateMillis, it.notes) },
        )
    }
    val insights = remember(events) { PayCalendar.insights(events) }
    val next = events.firstOrNull()
    val dateFormat = remember { SimpleDateFormat("EEE, MMM d, yyyy", Locale.US) }
    val monthFormat = remember { SimpleDateFormat("MMMM yyyy", Locale.US) }
    val scope = rememberCoroutineScope()
    var showAdd by remember { mutableStateOf(false) }
    var title by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var payDate by remember { mutableStateOf(System.currentTimeMillis() + 14L * 86400000) }
    var pickingDate by remember { mutableStateOf(false) }
    var insightsExpanded by remember { mutableStateOf(false) }
    val colors = appSemanticColors()

    if (requestAdd) {
        LaunchedEffect(requestAdd) {
            showAdd = true
            onAddHandled()
        }
    }

    val grouped = remember(events) {
        events.groupBy {
            val cal = Calendar.getInstance().apply { timeInMillis = it.dateMillis }
            cal.get(Calendar.YEAR) * 100 + cal.get(Calendar.MONTH)
        }
    }

    M3FlatScreenBackground {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(contentPadding),
            contentPadding = PaddingValues(AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            item {
                NextPayPeriodCard(
                    title = next?.title ?: "No upcoming pay",
                    dateLabel = next?.let { dateFormat.format(Date(it.dateMillis)) },
                    daysUntil = next?.let { PayCalendar.daysUntil(it.dateMillis) },
                )
            }
            item {
                CollapsibleInsightsCard(
                    insights = insights,
                    expanded = insightsExpanded,
                    onToggle = { insightsExpanded = !insightsExpanded },
                )
            }
            if (specials.isNotEmpty()) {
                item {
                    Text("Special pays", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                }
                items(specials, key = { it.id }) { special ->
                    M3SurfaceCard {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Surface(
                                shape = MaterialTheme.shapes.medium,
                                color = MaterialTheme.colorScheme.tertiaryContainer,
                                tonalElevation = 0.dp,
                            ) {
                                Icon(
                                    Icons.Default.Star,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onTertiaryContainer,
                                    modifier = Modifier.padding(10.dp),
                                )
                            }
                            Column(modifier = Modifier.weight(1f)) {
                                Text(special.title, fontWeight = FontWeight.SemiBold)
                                Text(
                                    dateFormat.format(Date(special.dateMillis)),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                            IconButton(onClick = {
                                scope.launch {
                                    container.database.specialPayDao().delete(special.id)
                                    appState.syncWidgets()
                                }
                            }) {
                                Icon(Icons.Default.Delete, contentDescription = "Delete", tint = colors.danger)
                            }
                        }
                    }
                }
            }
            grouped.toSortedMap().forEach { (_, monthEvents) ->
                val header = monthFormat.format(Date(monthEvents.first().dateMillis))
                item { Text(header, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                items(monthEvents, key = { it.id }) { event ->
                    val gaps = PayCalendar.payGaps(events)
                    val gapAfter = gaps.firstOrNull { it.prior.id == event.id }
                    PayEventRow(
                        title = event.title,
                        dateLabel = dateFormat.format(Date(event.dateMillis)),
                        daysUntil = PayCalendar.daysUntil(event.dateMillis),
                        gapDays = gapAfter?.gapDays,
                        isLongGap = gapAfter?.isLongGap == true,
                        isSpecial = event.isSpecial,
                    )
                }
            }
            item {
                M3SurfaceCard {
                    Text("About regular pay", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        "Mid-month pay is typically the 15th; month-end pay is typically the 1st. Weekend/holiday adjustments move pay to the prior business day.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }

    if (showAdd) {
        AlertDialog(
            onDismissRequest = { showAdd = false },
            title = { Text("Add special pay", style = MaterialTheme.typography.headlineSmall) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(value = title, onValueChange = { title = it }, label = { Text("Title") }, singleLine = true,
            shape = AppTextFieldDefaults.shape,
            colors = AppTextFieldDefaults.colors(),
        )
                    OutlinedTextField(value = notes, onValueChange = { notes = it }, label = { Text("Notes (optional)") },
            shape = AppTextFieldDefaults.shape,
            colors = AppTextFieldDefaults.colors(),
        )
                    TextButton(
                        onClick = { pickingDate = true },
                        colors = AppButtonDefaults.text(),
                    ) {
                        Text("Date: ${dateFormat.format(Date(payDate))}")
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        scope.launch {
                            container.database.specialPayDao().upsert(
                                SpecialPayEntity(UUID.randomUUID().toString(), title.trim(), payDate, notes.ifBlank { null }),
                            )
                            appState.syncWidgets()
                            showAdd = false
                            title = ""
                            notes = ""
                        }
                    },
                    colors = AppButtonDefaults.text(),
                ) { Text("Save") }
            },
            dismissButton = {
                TextButton(
                    onClick = { showAdd = false },
                    colors = AppButtonDefaults.text(),
                ) { Text("Cancel") }
            },
        )
    }

    if (pickingDate) {
        val state = rememberDatePickerState(initialSelectedDateMillis = payDate)
        DatePickerDialog(
            onDismissRequest = { pickingDate = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let { payDate = it }
                    pickingDate = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { pickingDate = false }) { Text("Cancel") } },
        ) { DatePicker(state = state) }
    }
}

@Composable
fun PayCalendarAddAction(onAdd: () -> Unit) {
    IconButton(onClick = onAdd) {
        Icon(Icons.Default.Add, contentDescription = "Add special pay", tint = appSemanticColors().accent)
    }
}

@Composable
private fun NextPayPeriodCard(title: String, dateLabel: String?, daysUntil: Int?) {
    val scheme = MaterialTheme.colorScheme
    M3SurfaceCard {
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = scheme.primaryContainer,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    Icons.Default.AttachMoney,
                    contentDescription = null,
                    tint = scheme.onPrimaryContainer,
                    modifier = Modifier.padding(12.dp),
                )
            }
            Column {
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                dateLabel?.let {
                    Text(it, style = MaterialTheme.typography.bodyMedium, color = scheme.onSurfaceVariant)
                }
                daysUntil?.let {
                    Text(
                        "$it",
                        style = MaterialTheme.typography.displaySmall,
                        fontWeight = FontWeight.Bold,
                        color = scheme.onSurface,
                    )
                    Text("days", style = MaterialTheme.typography.bodySmall, color = scheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun CollapsibleInsightsCard(
    insights: List<PayCalendarInsight>,
    expanded: Boolean,
    onToggle: () -> Unit,
) {
    val colors = appSemanticColors()
    val summary = PayCalendar.insightSummary(insights)
    M3SurfaceCard(onClick = onToggle) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Insights", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                if (!expanded) {
                    Text(summary, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Surface(
                shape = MaterialTheme.shapes.extraLarge,
                color = MaterialTheme.colorScheme.secondaryContainer,
                tonalElevation = 0.dp,
            ) {
                Text(
                    "${insights.size}",
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                )
            }
            Icon(
                if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                contentDescription = if (expanded) "Collapse" else "Expand",
            )
        }
        AnimatedVisibility(
            visible = expanded,
            enter = expandVertically() + fadeIn(animationSpec = AppMotion.accordionTween),
            exit = shrinkVertically() + fadeOut(animationSpec = AppMotion.accordionTween),
        ) {
            Column(modifier = Modifier.padding(top = 14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                insights.forEachIndexed { index, insight ->
                    if (index > 0) HorizontalDivider()
                    if (insight.featured && insight.gapDays != null) {
                        FeaturedGapInsight(insight)
                    } else {
                        PayInsightRow(insight)
                    }
                }
            }
        }
    }
}

@Composable
private fun FeaturedGapInsight(insight: PayCalendarInsight) {
    val colors = appSemanticColors()
    M3NestedSurface {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Default.Warning, contentDescription = null, tint = colors.warning)
            Column {
                Text(insight.title, fontWeight = FontWeight.SemiBold)
                Text(
                    "${insight.gapDays}",
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = colors.warning,
                )
                Text("days between pays", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(insight.message, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun PayInsightRow(insight: PayCalendarInsight) {
    val colors = appSemanticColors()
    val tint = when (insight.severity) {
        PayInsightSeverity.Warning -> colors.warning
        PayInsightSeverity.Info -> colors.info
    }
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
        Icon(
            if (insight.severity == PayInsightSeverity.Warning) Icons.Default.Warning else Icons.Default.Info,
            contentDescription = null,
            tint = tint,
        )
        Column {
            Text(insight.title, fontWeight = FontWeight.SemiBold)
            Text(insight.message, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun PayEventRow(
    title: String,
    dateLabel: String,
    daysUntil: Int,
    gapDays: Int?,
    isLongGap: Boolean,
    isSpecial: Boolean,
) {
    val scheme = MaterialTheme.colorScheme
    val colors = appSemanticColors()
    M3SurfaceCard {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = if (isSpecial) scheme.tertiaryContainer else scheme.primaryContainer,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    imageVector = if (isSpecial) Icons.Default.Star else Icons.Default.AttachMoney,
                    contentDescription = null,
                    tint = if (isSpecial) scheme.onTertiaryContainer else scheme.onPrimaryContainer,
                    modifier = Modifier.padding(10.dp),
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Text(dateLabel, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("in $daysUntil days", style = MaterialTheme.typography.labelSmall, color = scheme.primary)
                gapDays?.let {
                    Surface(
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(8.dp),
                        color = if (isLongGap) colors.warning.copy(alpha = 0.12f) else scheme.surfaceContainerHighest,
                    ) {
                        Text(
                            "$it day gap to next",
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isLongGap) colors.warning else MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        }
    }
}
