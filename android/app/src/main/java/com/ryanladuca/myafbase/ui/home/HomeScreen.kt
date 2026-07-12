package com.ryanladuca.myafbase.ui.home

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.ExploreDestination
import com.ryanladuca.myafbase.data.repository.WeatherSnapshot
import com.ryanladuca.myafbase.domain.logic.PayCalendar
import com.ryanladuca.myafbase.domain.logic.ReadinessStatus
import com.ryanladuca.myafbase.domain.model.BookmarkResolver
import com.ryanladuca.myafbase.domain.model.BookmarkTargetType
import com.ryanladuca.myafbase.domain.model.HomeSavedCategory
import com.ryanladuca.myafbase.domain.model.ReminderItem
import com.ryanladuca.myafbase.domain.model.ResolvedBookmark
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Surface
import com.ryanladuca.myafbase.ui.components.SectionHeader
import com.ryanladuca.myafbase.ui.components.WeatherHeroSection
import com.ryanladuca.myafbase.ui.explore.openMaps
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppMotion
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onPickBase: () -> Unit,
    onOpenTool: (String) -> Unit,
    onOpenExplore: () -> Unit,
    onOpenReminders: () -> Unit,
    showEmergencySheet: Boolean = false,
    onEmergencySheetDismiss: () -> Unit = {},
    contentPadding: PaddingValues,
) {
    val appState = LocalAppState.current
    val container = LocalAppContainer.current
    val baseState by appState.currentBase.collectAsState()
    val weatherEnabled by appState.weatherEnabled.collectAsState()
    val isLoading by appState.isLoading.collectAsState()
    val baseId = baseState?.id
    val bookmarks = if (baseId != null) {
        container.database.bookmarkDao().observeForBase(baseId).collectAsState(initial = emptyList()).value
    } else {
        emptyList()
    }
    val assignment = if (baseId != null) {
        container.database.assignmentDao().observe(baseId).collectAsState(initial = null).value
    } else null
    val readiness = if (baseId != null) {
        container.database.readinessDao().observe(baseId).collectAsState(initial = null).value
    } else null
    var weather by remember { mutableStateOf<WeatherSnapshot?>(null) }
    var weatherLoading by remember { mutableStateOf(false) }
    var showEmergency by remember { mutableStateOf(false) }
    var savedCategory by remember { mutableStateOf(HomeSavedCategory.ALL) }
    val dismissedReminderIds by container.preferences.dismissedReminderIds.collectAsState(initial = emptySet())
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val scheme = MaterialTheme.colorScheme

    LaunchedEffect(baseState?.id, weatherEnabled) {
        val b = baseState
        if (b != null && weatherEnabled) {
            weatherLoading = true
            weather = container.weatherRepository.fetch(b.latitude, b.longitude)
            weatherLoading = false
            appState.updateWeatherSnapshot(weather)
        } else {
            weather = null
            weatherLoading = false
            appState.updateWeatherSnapshot(null)
        }
    }

    LaunchedEffect(showEmergencySheet) {
        if (showEmergencySheet) {
            showEmergency = true
            onEmergencySheetDismiss()
        }
    }

    val base = baseState
    if (base == null) {
        com.ryanladuca.myafbase.ui.components.EmptyBasePrompt(onPickBase = onPickBase, contentPadding = contentPadding)
        return
    }

    val resolved = remember(base, bookmarks) { BookmarkResolver.resolve(base, bookmarks) }
    val filteredSaved = BookmarkResolver.filter(resolved, savedCategory)
    val displayedSaved = if (savedCategory == HomeSavedCategory.ALL) filteredSaved.take(10) else filteredSaved

    val homeReminders = remember(readiness, dismissedReminderIds) {
        buildHomeReminders(readiness).filter { it.id !in dismissedReminderIds }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(scheme.background)
            .padding(contentPadding),
    ) {
        PullToRefreshBox(
            isRefreshing = isLoading,
            onRefresh = {
                appState.refreshAll()
                scope.launch {
                    weatherLoading = true
                    weather = container.weatherRepository.fetch(base.latitude, base.longitude, forceRefresh = true)
                    weatherLoading = false
                    appState.updateWeatherSnapshot(weather)
                }
            },
            modifier = Modifier.fillMaxSize(),
        ) {
            LazyColumn(
                contentPadding = PaddingValues(AppTokens.screenPadding),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        WeatherHeroSection(
                            base = base,
                            showWeather = weatherEnabled,
                            weatherThemeKey = weather?.themeKey,
                            weatherConditionLabel = weather?.conditionLabel,
                            temperatureF = weather?.tempF?.roundToInt(),
                            feelsLikeF = weather?.feelsLikeDisplayF(),
                            windMph = weather?.windMph?.roundToInt(),
                            humidity = weather?.humidity,
                            weatherLoading = weatherLoading,
                            onRefresh = {
                                scope.launch {
                                    weatherLoading = true
                                    weather = container.weatherRepository.fetch(
                                        base.latitude,
                                        base.longitude,
                                        forceRefresh = true,
                                    )
                                    weatherLoading = false
                                    appState.updateWeatherSnapshot(weather)
                                }
                            },
                        )
                        EmergencyContactsCard(
                            count = base.emergencyNumbers.size,
                            baseName = base.name,
                            onClick = { showEmergency = true },
                        )
                    }
                }
                item {
                    HomeAssignmentBanner(
                        baseName = base.name,
                        profile = assignment,
                        onOpenAssignment = { appState.openAssignment() },
                    )
                }
                if (homeReminders.isNotEmpty()) {
                    item {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            SectionHeader(
                                title = "Reminders",
                                prominent = true,
                                primaryAction = when {
                                    homeReminders.size >= 2 -> "Clear All"
                                    else -> "See All"
                                },
                                onPrimaryAction = {
                                    if (homeReminders.size >= 2) {
                                        scope.launch {
                                            container.preferences.dismissAllReminders(homeReminders.map { it.id }.toSet())
                                        }
                                    } else {
                                        onOpenReminders()
                                    }
                                },
                            )
                            homeReminders.take(2).forEach { reminder ->
                                HomeReminderRow(
                                    reminder = reminder,
                                    onDismiss = {
                                        scope.launch { container.preferences.dismissReminder(reminder.id) }
                                    },
                                    onClick = onOpenReminders,
                                )
                            }
                        }
                    }
                }
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        SectionHeader(title = "Tools", prominent = true)
                        HomeToolsBentoGrid(onOpenTool = onOpenTool)
                    }
                }
                item {
                    HomeSavedSection(
                        savedCategory = savedCategory,
                        onCategorySelected = { savedCategory = it },
                        items = displayedSaved,
                        totalFilteredCount = filteredSaved.size,
                        showTruncationHint = savedCategory == HomeSavedCategory.ALL && filteredSaved.size > 10,
                        onOpenExplore = onOpenExplore,
                        onOpenItem = { item ->
                            val type = BookmarkTargetType.fromRaw(item.bookmark.targetType)
                            appState.openExplore(
                                ExploreDestination(
                                    segment = if (type == BookmarkTargetType.EVENT) "events" else "resources",
                                    category = when (item) {
                                        is ResolvedBookmark.ResourceItem -> item.resource.category
                                        is ResolvedBookmark.GateItem -> "gates"
                                        else -> "all"
                                    },
                                    targetType = type,
                                    targetId = item.bookmark.targetId,
                                )
                            )
                        },
                        onUnbookmark = { item ->
                            scope.launch { container.database.bookmarkDao().delete(item.bookmark.id) }
                        },
                        onDirections = { item ->
                            when (item) {
                                is ResolvedBookmark.GateItem -> openMaps(
                                    context, item.gate.latitude, item.gate.longitude,
                                    item.gate.address ?: item.gate.name,
                                )
                                is ResolvedBookmark.ResourceItem -> openMaps(
                                    context, item.resource.latitude, item.resource.longitude,
                                    item.resource.displayAddress ?: item.resource.name,
                                )
                                else -> Unit
                            }
                        },
                        onCall = { item ->
                            if (item is ResolvedBookmark.ResourceItem) {
                                item.resource.displayPhone?.let {
                                    context.startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$it")))
                                }
                            }
                        },
                    )
                }
                item {
                    Text(
                        "Unofficial community tool. Not affiliated with the DoD or U.S. Air Force. Verify all information with official sources.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }

    if (showEmergency) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { showEmergency = false },
            title = { Text("Emergency contacts", style = MaterialTheme.typography.headlineSmall) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Verify numbers with your installation before relying on them in an emergency.", style = MaterialTheme.typography.bodyMedium)
                    base.emergencyNumbers.forEach { number ->
                        TextButton(
                            onClick = {
                                context.startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:${number.number}")))
                            },
                            colors = AppButtonDefaults.text(),
                        ) {
                            Text("${number.label}: ${number.number}")
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = { showEmergency = false },
                    colors = AppButtonDefaults.text(),
                ) { Text("Close") }
            },
        )
    }
}

@Composable
private fun HomeSurfaceCard(
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
    content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    if (onClick != null) {
        Surface(
            onClick = onClick,
            modifier = modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.extraLarge,
            color = scheme.surfaceContainerLow,
            tonalElevation = 0.dp,
        ) {
            Column(
                modifier = Modifier.padding(AppTokens.contentPadding),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                content = content,
            )
        }
    } else {
        Surface(
            modifier = modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.extraLarge,
            color = scheme.surfaceContainerLow,
            tonalElevation = 0.dp,
        ) {
            Column(
                modifier = Modifier.padding(AppTokens.contentPadding),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                content = content,
            )
        }
    }
}

@Composable
private fun EmergencyContactsCard(count: Int, baseName: String, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    HomeSurfaceCard(onClick = onClick) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = scheme.errorContainer,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    Icons.Default.Warning,
                    contentDescription = null,
                    tint = scheme.onErrorContainer,
                    modifier = Modifier
                        .padding(10.dp)
                        .size(20.dp),
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text("Emergency contacts", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    "$count numbers for $baseName",
                    style = MaterialTheme.typography.bodyMedium,
                    color = scheme.onSurfaceVariant,
                )
            }
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = scheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun HomeReminderRow(reminder: ReminderItem, onDismiss: () -> Unit, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    val dateFormat = remember { SimpleDateFormat("EEE, MMM d", Locale.US) }
    val days = PayCalendar.daysUntil(reminder.dueMillis)
    val statusContainer = when (ReadinessStatus.evaluate(reminder.dueMillis)) {
        ReadinessStatus.OVERDUE -> scheme.errorContainer
        ReadinessStatus.DUE_SOON -> scheme.tertiaryContainer
        else -> scheme.primaryContainer
    }
    val statusContent = when (ReadinessStatus.evaluate(reminder.dueMillis)) {
        ReadinessStatus.OVERDUE -> scheme.onErrorContainer
        ReadinessStatus.DUE_SOON -> scheme.onTertiaryContainer
        else -> scheme.onPrimaryContainer
    }
    var visible by remember(reminder.id) { mutableStateOf(true) }
    val scale by animateFloatAsState(
        targetValue = if (visible) 1f else AppMotion.reminderDismissScale,
        animationSpec = AppMotion.reminderDismissSpring,
        label = "reminderScale",
    )
    AnimatedVisibility(
        visible = visible,
        exit = shrinkVertically() + fadeOut(),
    ) {
        HomeSurfaceCard(onClick = onClick, modifier = Modifier.scale(scale)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Surface(
                    shape = MaterialTheme.shapes.medium,
                    color = statusContainer,
                    tonalElevation = 0.dp,
                ) {
                    Icon(
                        Icons.Default.Warning,
                        contentDescription = null,
                        tint = statusContent,
                        modifier = Modifier
                            .padding(8.dp)
                            .size(18.dp),
                    )
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(reminder.title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold)
                    Text(
                        "${dateFormat.format(Date(reminder.dueMillis))} · in $days days",
                        style = MaterialTheme.typography.bodySmall,
                        color = scheme.onSurfaceVariant,
                    )
                }
                IconButton(onClick = {
                    visible = false
                    onDismiss()
                }) {
                    Icon(Icons.Default.Close, contentDescription = "Dismiss reminder")
                }
            }
        }
    }
}

private fun buildHomeReminders(readiness: com.ryanladuca.myafbase.data.db.ReadinessEntity?): List<ReminderItem> {
    if (readiness == null) return emptyList()
    val candidates = listOfNotNull(
        readiness.fitnessTestDueMillis?.let { ReminderItem("fitness", "Fitness test due", it, "readiness") },
        readiness.dentalDueMillis?.let { ReminderItem("dental", "Dental due", it, "readiness") },
        readiness.evalCloseoutDueMillis?.let { ReminderItem("eval", "Eval closeout", it, "readiness") },
        readiness.cacExpirationMillis?.let { ReminderItem("cac", "CAC expiration", it, "readiness") },
        readiness.clearanceRenewalMillis?.let { ReminderItem("clearance", "Clearance renewal", it, "readiness") },
    ).sortedBy { it.dueMillis }
    val urgent = candidates.filter {
        ReadinessStatus.evaluate(it.dueMillis) in listOf(ReadinessStatus.OVERDUE, ReadinessStatus.DUE_SOON)
    }
    return if (urgent.isNotEmpty()) urgent else candidates.take(1)
}

private fun buildHomeReminder(readiness: com.ryanladuca.myafbase.data.db.ReadinessEntity?): ReminderItem? =
    buildHomeReminders(readiness).firstOrNull()
