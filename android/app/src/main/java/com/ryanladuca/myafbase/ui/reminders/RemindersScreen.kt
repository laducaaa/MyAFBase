package com.ryanladuca.myafbase.ui.reminders

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.logic.PayCalendar
import com.ryanladuca.myafbase.domain.logic.ReadinessStatus
import com.ryanladuca.myafbase.domain.logic.SpecialPayEntry
import com.ryanladuca.myafbase.domain.model.ReminderItem
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.EmptyBasePrompt
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.components.SectionHeader
import com.ryanladuca.myafbase.ui.theme.AppTokens
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun RemindersScreen(
    onPickBase: () -> Unit,
    onOpenPayCalendar: () -> Unit = {},
    onOpenWarTracker: () -> Unit = {},
    contentPadding: PaddingValues,
) {
    val appState = LocalAppState.current
    val container = LocalAppContainer.current
    val baseState by appState.currentBase.collectAsState()
    val dateFormat = remember { SimpleDateFormat("EEE, MMM d", Locale.US) }

    val base = baseState
    if (base == null) {
        EmptyBasePrompt(onPickBase = onPickBase, contentPadding = contentPadding)
        return
    }

    val readiness by container.database.readinessDao().observe(base.id).collectAsState(initial = null)
    val warDeadlines by container.database.warAwardDeadlineDao().observeForBase(base.id)
        .collectAsState(initial = emptyList())
    val specials by container.database.specialPayDao().observeAll().collectAsState(initial = emptyList())
    val nextPay = remember(specials) {
        PayCalendar.upcomingEvents(
            monthsAhead = 2,
            specialPays = specials.map { SpecialPayEntry(it.id, it.title, it.dateMillis, it.notes) },
        ).firstOrNull()
    }

    val readinessReminders = buildList {
        fun add(id: String, title: String, millis: Long?) {
            if (millis != null) add(ReminderItem(id, title, millis, "readiness"))
        }
        add("fitness", "Fitness test due", readiness?.fitnessTestDueMillis)
        add("dental", "Dental due", readiness?.dentalDueMillis)
        add("eval", "Eval closeout", readiness?.evalCloseoutDueMillis)
        add("cac", "CAC expiration", readiness?.cacExpirationMillis)
        add("clearance", "Clearance renewal", readiness?.clearanceRenewalMillis)
    }.sortedBy { it.dueMillis }

    val warReminders = warDeadlines.map {
        ReminderItem("award-${it.id}", "Award: ${it.title}", it.deadlineMillis, "war")
    }.sortedBy { it.dueMillis }

    M3FlatScreenBackground {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(contentPadding),
            contentPadding = PaddingValues(AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            nextPay?.let { pay ->
                item {
                    NextPayReminderCard(
                        title = pay.title,
                        daysUntil = PayCalendar.daysUntil(pay.dateMillis),
                        dateLabel = dateFormat.format(Date(pay.dateMillis)),
                        onClick = onOpenPayCalendar,
                    )
                }
            }

            item {
                RemindersSection(
                    title = "Readiness",
                    emptyTitle = "No readiness dates set",
                    emptyBody = "Set dates in Assignment → Readiness tracker.",
                    items = readinessReminders,
                    dateFormat = dateFormat,
                )
            }

            item {
                RemindersSection(
                    title = "WAR awards",
                    primaryAction = "Open WAR Tracker",
                    onPrimaryAction = onOpenWarTracker,
                    emptyTitle = "No award deadlines",
                    emptyBody = "Add deadlines in WAR Tracker.",
                    items = warReminders,
                    dateFormat = dateFormat,
                    onItemClick = onOpenWarTracker,
                    onEmptyClick = onOpenWarTracker,
                )
            }
        }
    }
}

@Composable
private fun NextPayReminderCard(
    title: String,
    daysUntil: Int,
    dateLabel: String,
    onClick: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = scheme.surfaceContainerHigh,
        tonalElevation = 1.dp,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
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
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("Next pay", style = MaterialTheme.typography.labelMedium, color = scheme.onSurfaceVariant)
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    "$daysUntil days · $dateLabel",
                    style = MaterialTheme.typography.bodyMedium,
                    color = scheme.primary,
                    fontWeight = FontWeight.Medium,
                )
            }
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = scheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun RemindersSection(
    title: String,
    emptyTitle: String,
    emptyBody: String,
    items: List<ReminderItem>,
    dateFormat: SimpleDateFormat,
    primaryAction: String? = null,
    onPrimaryAction: (() -> Unit)? = null,
    onItemClick: (() -> Unit)? = null,
    onEmptyClick: (() -> Unit)? = null,
) {
    val scheme = MaterialTheme.colorScheme

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionHeader(
            title = title,
            primaryAction = primaryAction,
            onPrimaryAction = onPrimaryAction,
        )
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.extraLarge,
            color = scheme.surfaceContainerHigh,
            tonalElevation = 1.dp,
        ) {
            if (items.isEmpty()) {
                ReminderEmptyState(
                    title = emptyTitle,
                    body = emptyBody,
                    onClick = onEmptyClick,
                )
            } else {
                Column(modifier = Modifier.fillMaxWidth()) {
                    items.forEachIndexed { index, item ->
                        ReminderListItem(
                            item = item,
                            dateFormat = dateFormat,
                            onClick = onItemClick,
                        )
                        if (index < items.lastIndex) {
                            HorizontalDivider(
                                modifier = Modifier.padding(horizontal = 16.dp),
                                color = scheme.outlineVariant,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ReminderEmptyState(
    title: String,
    body: String,
    onClick: (() -> Unit)?,
) {
    val scheme = MaterialTheme.colorScheme
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text(body, style = MaterialTheme.typography.bodyMedium, color = scheme.onSurfaceVariant)
    }
}

@Composable
private fun ReminderListItem(
    item: ReminderItem,
    dateFormat: SimpleDateFormat,
    onClick: (() -> Unit)?,
) {
    val scheme = MaterialTheme.colorScheme
    val days = PayCalendar.daysUntil(item.dueMillis)
    val status = ReadinessStatus.evaluate(item.dueMillis)
    val (containerColor, contentColor) = reminderIconColors(status, item.category, scheme)
    val icon = if (item.category == "war") Icons.Default.Star else Icons.Default.Warning

    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
        colors = ListItemDefaults.colors(containerColor = scheme.surfaceContainerHigh),
        leadingContent = {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = containerColor,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = contentColor,
                    modifier = Modifier
                        .padding(10.dp)
                        .size(20.dp),
                )
            }
        },
        headlineContent = {
            Text(
                item.title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        },
        supportingContent = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    "${dateFormat.format(Date(item.dueMillis))} · in $days days",
                    style = MaterialTheme.typography.bodySmall,
                    color = scheme.onSurfaceVariant,
                )
                ReminderStatusChip(status = status)
            }
        },
        trailingContent = {
            if (onClick != null) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = scheme.onSurfaceVariant,
                )
            }
        },
    )
}

@Composable
private fun ReminderStatusChip(status: ReadinessStatus) {
    val scheme = MaterialTheme.colorScheme
    val (containerColor, contentColor) = when (status) {
        ReadinessStatus.OVERDUE -> scheme.errorContainer to scheme.onErrorContainer
        ReadinessStatus.DUE_SOON -> scheme.tertiaryContainer to scheme.onTertiaryContainer
        ReadinessStatus.ON_TRACK -> scheme.primaryContainer to scheme.onPrimaryContainer
        ReadinessStatus.WINDOW_OPEN -> scheme.secondaryContainer to scheme.onSecondaryContainer
        ReadinessStatus.NOT_SET -> scheme.surfaceContainerHighest to scheme.onSurfaceVariant
    }
    Surface(
        shape = MaterialTheme.shapes.small,
        color = containerColor,
        tonalElevation = 0.dp,
    ) {
        Text(
            text = status.label,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = contentColor,
        )
    }
}

private fun reminderIconColors(
    status: ReadinessStatus,
    category: String,
    scheme: androidx.compose.material3.ColorScheme,
): Pair<Color, Color> {
    if (category == "war") {
        return scheme.secondaryContainer to scheme.onSecondaryContainer
    }
    return when (status) {
        ReadinessStatus.OVERDUE -> scheme.errorContainer to scheme.onErrorContainer
        ReadinessStatus.DUE_SOON -> scheme.tertiaryContainer to scheme.onTertiaryContainer
        else -> scheme.primaryContainer to scheme.onPrimaryContainer
    }
}
