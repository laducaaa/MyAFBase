package com.ryanladuca.myafbase.ui.tools

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.PfraRecordEntity
import com.ryanladuca.myafbase.domain.logic.PFRACardioEvent
import com.ryanladuca.myafbase.domain.logic.PFRACoreEvent
import com.ryanladuca.myafbase.domain.logic.PFRAGender
import com.ryanladuca.myafbase.domain.logic.PFRARecordKind
import com.ryanladuca.myafbase.domain.logic.PFRAScoring
import com.ryanladuca.myafbase.domain.logic.PFRAStrengthEvent
import com.ryanladuca.myafbase.domain.logic.PFRATargetTier
import com.ryanladuca.myafbase.domain.logic.PFRATrends
import com.ryanladuca.myafbase.domain.logic.PfraRecordSnapshot
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.components.AppCard
import com.ryanladuca.myafbase.ui.components.AppCardNested
import com.ryanladuca.myafbase.ui.components.AppScreenBackground
import com.ryanladuca.myafbase.ui.components.CapsuleProgressBar
import com.ryanladuca.myafbase.ui.components.IconBadge
import com.ryanladuca.myafbase.ui.components.KeyValueRow
import com.ryanladuca.myafbase.ui.components.SectionCard
import com.ryanladuca.myafbase.ui.components.StatusPill
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.ui.theme.appSemanticColors
import com.ryanladuca.myafbase.ui.theme.heroNumberTypography
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PfraRecordsScreen(contentPadding: PaddingValues) {
    val container = LocalAppContainer.current
    val records by container.database.pfraDao().observeAll().collectAsState(initial = emptyList())
    var kindFilter by remember { mutableStateOf<PFRARecordKind?>(null) }
    var selectedIds by remember { mutableStateOf(setOf<String>()) }
    var detailRecord by remember { mutableStateOf<PfraRecordEntity?>(null) }
    val scope = rememberCoroutineScope()
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.US) }
    val shortDateFormat = remember { SimpleDateFormat("MMM d", Locale.US) }
    val colors = appSemanticColors()

    val filtered = records.filter { kindFilter == null || it.kind == kindFilter!!.name }
    val trends = PFRATrends.summarize(filtered.map { it.score to it.passed })
    val componentAvgs = PFRATrends.componentAverages(filtered.map { it.detailsJson })
    val compareRecords = filtered.filter { it.id in selectedIds }.take(3)
    val snapshots = compareRecords.map { record ->
        PfraRecordSnapshot(
            id = record.id,
            dateMillis = record.dateMillis,
            score = record.score,
            passed = record.passed,
            components = PFRATrends.parseComponentDetails(record.detailsJson).toMap(),
        )
    }
    val insights = PFRATrends.comparisonInsights(snapshots) { shortDateFormat.format(Date(it)) }

    AppScreenBackground {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding),
            contentPadding = PaddingValues(AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            item {
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    FilterChip(
                        selected = kindFilter == null,
                        onClick = { kindFilter = null },
                        label = { Text("All") },
                        colors = AppChipDefaults.filterChip(selected = kindFilter == null),
                    )
                    PFRARecordKind.entries.forEach { kind ->
                        FilterChip(
                            selected = kindFilter == kind,
                            onClick = { kindFilter = kind },
                            label = { Text(kind.title) },
                            colors = AppChipDefaults.filterChip(selected = kindFilter == kind),
                        )
                    }
                }
            }

            item {
                PfraTrendsCard(
                    trends = trends,
                    scoresOldestFirst = filtered.asReversed().map { it.score },
                    componentAvgs = componentAvgs,
                )
            }

            if (compareRecords.size >= 2) {
                item {
                    PfraComparisonCard(
                        records = compareRecords,
                        insights = insights,
                        dateFormat = shortDateFormat,
                    )
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("History", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        if (filtered.isEmpty()) {
                            "No scores in this filter."
                        } else {
                            "Tap a row for details. Select up to 3 scores to compare."
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            if (filtered.isEmpty()) {
                item {
                    SectionCard(title = "No records yet", subtitle = "Save a score from PFRA Score or Goals.")
                }
            } else {
                items(filtered, key = { it.id }) { record ->
                    PfraHistoryRow(
                        record = record,
                        selected = record.id in selectedIds,
                        dateFormat = dateFormat,
                        onToggleSelect = {
                            selectedIds = when {
                                record.id in selectedIds -> selectedIds - record.id
                                selectedIds.size < 3 -> selectedIds + record.id
                                else -> {
                                    val drop = filtered.lastOrNull { it.id in selectedIds }?.id
                                    if (drop != null) (selectedIds - drop) + record.id else selectedIds + record.id
                                }
                            }
                        },
                        onOpen = { detailRecord = record },
                    )
                }
            }

            item {
                TextButton(
                    onClick = { scope.launch { container.database.pfraDao().deleteAll() } },
                    colors = AppButtonDefaults.text(),
                ) {
                    Text("Clear all records", color = colors.danger)
                }
            }
        }
    }

    detailRecord?.let { record ->
        ModalBottomSheet(
            onDismissRequest = { detailRecord = null },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        ) {
            PfraRecordDetailSheet(
                record = record,
                dateFormat = dateFormat,
                onLoad = {
                    loadRecordIntoProfile(container, record)
                    detailRecord = null
                },
                onDelete = {
                    scope.launch {
                        container.database.pfraDao().delete(record.id)
                        selectedIds = selectedIds - record.id
                        detailRecord = null
                    }
                },
            )
        }
    }
}

@Composable
private fun PfraTrendsCard(
    trends: com.ryanladuca.myafbase.domain.logic.PFRATrendsSummary,
    scoresOldestFirst: List<Double>,
    componentAvgs: List<com.ryanladuca.myafbase.domain.logic.PFRAComponentAverage>,
) {
    val colors = appSemanticColors()
    AppCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Text("COMPOSITE", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(
                trends.latestScore?.let { "%.1f".format(it) } ?: "—",
                style = heroNumberTypography(),
                color = colors.accent,
            )
            if (scoresOldestFirst.size >= 2) {
                PfraScoreLineChart(scores = scoresOldestFirst)
            }
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                TrendStat("Best", trends.bestScore?.let { "%.1f".format(it) } ?: "—")
                TrendStat("Average", trends.averageScore?.let { "%.1f".format(it) } ?: "—")
                TrendStat(
                    "Pass rate",
                    trends.passRate?.let { "${(it * 100).roundToInt()}%" } ?: "—",
                )
            }
            if (componentAvgs.isNotEmpty()) {
                Text("Component averages", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                componentAvgs.forEach { avg ->
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(
                                if (avg.name == "Body Composition") "Body" else avg.name,
                                style = MaterialTheme.typography.bodySmall,
                            )
                            Text("%.1f".format(avg.average), style = MaterialTheme.typography.labelMedium)
                        }
                        CapsuleProgressBar(
                            progress = (avg.average / avg.maxPoints).toFloat().coerceIn(0f, 1f),
                            height = 6.dp,
                            fillColor = colors.accent,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun TrendStat(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun PfraScoreLineChart(scores: List<Double>) {
    val colors = appSemanticColors()
    val passLine = PFRAScoring.PASS_COMPOSITE.toFloat()
    val minY = minOf(scores.minOrNull() ?: 0.0, passLine.toDouble()) - 5
    val maxY = maxOf(scores.maxOrNull() ?: 100.0, passLine.toDouble()) + 5
    val range = (maxY - minY).takeIf { it > 0 } ?: 1.0
    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(140.dp)
            .padding(vertical = 4.dp),
    ) {
        val stepX = if (scores.size == 1) size.width / 2f else size.width / (scores.size - 1)
        val passY = size.height * (1f - ((passLine - minY) / range).toFloat())
        drawLine(
            color = colors.success.copy(alpha = 0.35f),
            start = Offset(0f, passY),
            end = Offset(size.width, passY),
            strokeWidth = 2.dp.toPx(),
        )
        val path = Path()
        scores.forEachIndexed { index, score ->
            val x = index * stepX
            val y = size.height * (1f - ((score - minY) / range).toFloat())
            if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        drawPath(
            path = path,
            color = colors.accent,
            style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round),
        )
        scores.forEachIndexed { index, score ->
            val x = index * stepX
            val y = size.height * (1f - ((score - minY) / range).toFloat())
            drawCircle(color = colors.accent, radius = 5.dp.toPx(), center = Offset(x, y))
        }
    }
}

@Composable
private fun PfraComparisonCard(
    records: List<PfraRecordEntity>,
    insights: List<String>,
    dateFormat: SimpleDateFormat,
) {
    val colors = appSemanticColors()
    AppCard {
        Column(verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Compare", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    "${records.size} selected",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                records.forEach { record ->
                    AppCardNested(modifier = Modifier.weight(1f)) {
                        Text(dateFormat.format(Date(record.dateMillis)), style = MaterialTheme.typography.labelSmall)
                        Text("%.1f".format(record.score), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        Text(record.kind, style = MaterialTheme.typography.labelSmall, color = colors.accent)
                        Text(
                            record.rating,
                            style = MaterialTheme.typography.labelSmall,
                            color = if (record.passed) colors.success else colors.warning,
                        )
                    }
                }
            }
            if (insights.isNotEmpty()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(colors.highlight.copy(alpha = 0.10f), MaterialTheme.shapes.small)
                        .padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text("Insights", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                    insights.forEach { insight ->
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Icon(Icons.Default.Lightbulb, contentDescription = null, tint = colors.highlight, modifier = Modifier.size(16.dp))
                            Text(insight, style = MaterialTheme.typography.bodySmall, modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
            listOf("Body Composition", "Cardio", "Strength", "Core").forEach { name ->
                val values = records.map { PFRATrends.parseComponentDetails(it.detailsJson).toMap()[name] ?: 0.0 }
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        if (name == "Body Composition") "Body" else name,
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        values.forEachIndexed { index, value ->
                            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text("%.1f".format(value), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
                                CapsuleProgressBar(
                                    progress = (value / 60.0).toFloat().coerceIn(0f, 1f),
                                    height = 6.dp,
                                    fillColor = colors.accent.copy(alpha = if (index == 0) 1f else 0.45f),
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PfraHistoryRow(
    record: PfraRecordEntity,
    selected: Boolean,
    dateFormat: SimpleDateFormat,
    onToggleSelect: () -> Unit,
    onOpen: () -> Unit,
) {
    val colors = appSemanticColors()
    AppCard {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            IconButton(onClick = onToggleSelect) {
                Icon(
                    if (selected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                    contentDescription = if (selected) "Deselect" else "Select for comparison",
                    tint = if (selected) colors.brandPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clickable(role = Role.Button, onClick = onOpen),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                Text(dateFormat.format(Date(record.dateMillis)), style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold)
                Text(
                    "${record.kind} · ${record.rating}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text("%.1f".format(record.score), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                StatusPill(
                    text = if (record.passed) "Pass" else "Fail",
                    tint = if (record.passed) colors.success else colors.warning,
                )
            }
        }
    }
}

@Composable
private fun PfraRecordDetailSheet(
    record: PfraRecordEntity,
    dateFormat: SimpleDateFormat,
    onLoad: () -> Unit,
    onDelete: () -> Unit,
) {
    val colors = appSemanticColors()
    val components = PFRATrends.parseComponentDetails(record.detailsJson)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(AppTokens.screenPadding)
            .padding(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
    ) {
        StatusPill(text = record.kind, tint = colors.accent)
        Text("%.1f".format(record.score), style = heroNumberTypography())
        Text(
            "${record.rating} · ${if (record.passed) "Pass" else "Fail"}",
            style = MaterialTheme.typography.titleMedium,
            color = if (record.passed) colors.success else colors.warning,
        )
        Text(dateFormat.format(Date(record.dateMillis)), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        HorizontalDivider()
        components.forEach { (name, points) ->
            KeyValueRow(name, "%.1f".format(points))
        }
        record.note?.takeIf { it.isNotBlank() }?.let {
            Text(it, style = MaterialTheme.typography.bodyMedium)
        }
        TextButton(onClick = onLoad, modifier = Modifier.fillMaxWidth(), colors = AppButtonDefaults.text()) {
            Text("Load into calculator")
        }
        TextButton(onClick = onDelete, modifier = Modifier.fillMaxWidth(), colors = AppButtonDefaults.text()) {
            Text("Delete record", color = colors.danger)
        }
    }
}

private fun loadRecordIntoProfile(
    container: com.ryanladuca.myafbase.data.AppContainer,
    record: PfraRecordEntity,
) {
    val feet = (record.heightInches / 12).toInt()
    val inches = (record.heightInches % 12).roundToInt()
    val cardio = runCatching { PFRACardioEvent.valueOf(record.cardioEvent) }
        .getOrDefault(PFRACardioEvent.TWO_MILE_RUN)
    val core = runCatching { PFRACoreEvent.valueOf(record.coreEvent) }
        .getOrDefault(PFRACoreEvent.SIT_UPS)
    val runTotal = record.cardioValue.roundToInt()
    val coreTotal = record.coreValue.roundToInt()

    container.pfraProfileStore.update { current ->
        current.copy(
            gender = runCatching { PFRAGender.valueOf(record.gender) }.getOrDefault(current.gender),
            age = record.age,
            heightFeet = feet,
            heightInches = inches,
            waistTenths = (record.waistInches * 10).roundToInt(),
            cardioEvent = cardio,
            runMinutes = if (cardio == PFRACardioEvent.TWO_MILE_RUN) runTotal / 60 else current.runMinutes,
            runSeconds = if (cardio == PFRACardioEvent.TWO_MILE_RUN) runTotal % 60 else current.runSeconds,
            hamrShuttles = if (cardio == PFRACardioEvent.HAMR) runTotal else current.hamrShuttles,
            strengthEvent = runCatching { PFRAStrengthEvent.valueOf(record.strengthEvent) }
                .getOrDefault(current.strengthEvent),
            strengthReps = record.strengthReps,
            coreEvent = core,
            coreReps = if (core == PFRACoreEvent.FOREARM_PLANK) current.coreReps else coreTotal,
            plankMinutes = if (core == PFRACoreEvent.FOREARM_PLANK) coreTotal / 60 else current.plankMinutes,
            plankSeconds = if (core == PFRACoreEvent.FOREARM_PLANK) coreTotal % 60 else current.plankSeconds,
            targetTier = record.targetTier?.let {
                runCatching { PFRATargetTier.valueOf(it) }.getOrNull()
            } ?: current.targetTier,
        )
    }
}
