package com.ryanladuca.myafbase.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import com.ryanladuca.myafbase.data.db.WarEntryEntity
import com.ryanladuca.myafbase.domain.logic.WarDateMath
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.ryanladuca.myafbase.domain.model.HomeToolId
import com.ryanladuca.myafbase.ui.assignment.AssignmentScreen
import com.ryanladuca.myafbase.ui.components.BasePickerSheet
import com.ryanladuca.myafbase.ui.explore.ExploreScreen
import com.ryanladuca.myafbase.ui.home.HomeScreen
import com.ryanladuca.myafbase.ui.menu.LegalScreen
import com.ryanladuca.myafbase.ui.menu.MenuScreen
import com.ryanladuca.myafbase.ui.navigation.AppDestination
import com.ryanladuca.myafbase.ui.navigation.bottomTabs
import com.ryanladuca.myafbase.ui.onboarding.OnboardingScreen
import com.ryanladuca.myafbase.ui.reminders.RemindersScreen
import com.ryanladuca.myafbase.ui.theme.AppNavigationDefaults
import com.ryanladuca.myafbase.ui.theme.AppTopAppBarDefaults
import com.ryanladuca.myafbase.ui.tools.AfiSearchScreen
import com.ryanladuca.myafbase.ui.tools.FeedbackScreen
import com.ryanladuca.myafbase.ui.tools.LeavePlannerScreen
import com.ryanladuca.myafbase.ui.tools.PayCalendarScreen
import com.ryanladuca.myafbase.ui.tools.PfraGoalsScreen
import com.ryanladuca.myafbase.ui.tools.PfraRecordsScreen
import com.ryanladuca.myafbase.ui.tools.PfraScoreScreen
import com.ryanladuca.myafbase.ui.tools.WarQuickAddContext
import com.ryanladuca.myafbase.ui.tools.WarQuickAddSheet
import com.ryanladuca.myafbase.ui.tools.WarTrackerScreen
import kotlinx.coroutines.launch

private data class TabSpec(
    val destination: AppDestination,
    val label: String,
    val icon: ImageVector,
)

private fun tabTitle(route: String?): String? = when (route) {
    AppDestination.Home.route -> null
    AppDestination.Explore.route -> "Explore"
    AppDestination.Assignment.route -> "My Assignment"
    AppDestination.Reminders.route -> "Reminders"
    AppDestination.Menu.route -> "Menu"
    else -> null
}

private fun toolTitle(route: String?): String? = when (route) {
    AppDestination.PayCalendar.route -> "Pay Calendar"
    AppDestination.LeavePlanner.route -> "Leave Planner"
    AppDestination.PfraScore.route -> "PFRA Score Calculator"
    AppDestination.PfraGoals.route -> "PFRA Goals"
    AppDestination.PfraRecords.route -> "PFRA Records"
    AppDestination.WarTracker.route -> "WAR Tracker"
    AppDestination.AfiSearch.route -> "Essential AFI Search"
    AppDestination.Feedback.route -> "Feedback"
    AppDestination.Legal.route -> "Legal & Privacy"
    else -> null
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyAFBaseApp() {
    val appState = LocalAppState.current
    val container = LocalAppContainer.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val navController = rememberNavController()
    val hasOnboarded by appState.hasCompletedOnboarding.collectAsState()
    val selectedBaseId by appState.selectedBaseId.collectAsState()
    var showBasePicker by remember { mutableStateOf(false) }
    val pendingTool by appState.pendingToolRoute.collectAsState()
    val pendingTab by appState.pendingTab.collectAsState()
    val showWarQuickLog by appState.showWarQuickLog.collectAsState()
    val pendingWarText by appState.pendingWarQuickLogText.collectAsState()
    val showEmergencyRequest by appState.showEmergency.collectAsState()
    var payCalendarAddRequest by remember { mutableStateOf(false) }

    LaunchedEffect(hasOnboarded, selectedBaseId) {
        if (!hasOnboarded) {
            navController.navigate(AppDestination.Onboarding.route) { popUpTo(0) }
        } else if (selectedBaseId == null) {
            showBasePicker = true
        }
    }

    LaunchedEffect(pendingTool) {
        val tool = pendingTool ?: return@LaunchedEffect
        val route = when (tool) {
            HomeToolId.PFRA_SCORE.id -> AppDestination.PfraScore.route
            HomeToolId.PFRA_GOAL.id -> AppDestination.PfraGoals.route
            HomeToolId.AFI_SEARCH.id -> AppDestination.AfiSearch.route
            HomeToolId.WAR_TRACKER.id -> AppDestination.WarTracker.route
            HomeToolId.LEAVE_PLANNER.id -> AppDestination.LeavePlanner.route
            HomeToolId.PAY_CALENDAR.id -> AppDestination.PayCalendar.route
            else -> null
        }
        if (route != null) {
            navController.navigate(route)
            appState.consumeToolRoute()
        }
    }

    LaunchedEffect(pendingTab) {
        when (pendingTab) {
            "home" -> {
                appState.consumePendingTab()
                navController.navigate(AppDestination.Home.route) {
                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                    launchSingleTop = true
                    restoreState = true
                }
            }
            "explore" -> {
                appState.consumePendingTab()
                navController.navigate(AppDestination.Explore.route) {
                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                    launchSingleTop = true
                    restoreState = true
                }
            }
            "assignment" -> {
                appState.consumePendingTab()
                navController.navigate(AppDestination.Assignment.route) {
                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                    launchSingleTop = true
                    restoreState = true
                }
            }
            "reminders" -> {
                appState.consumePendingTab()
                navController.navigate(AppDestination.Reminders.route) {
                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        }
    }

    val tabs = listOf(
        TabSpec(AppDestination.Home, "Home", Icons.Default.Home),
        TabSpec(AppDestination.Explore, "Explore", Icons.Default.Explore),
        TabSpec(AppDestination.Assignment, "Assignment", Icons.AutoMirrored.Filled.Assignment),
        TabSpec(AppDestination.Reminders, "Reminders", Icons.Default.Notifications),
        TabSpec(AppDestination.Menu, "Menu", Icons.Default.Menu),
    )
    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    val showBottomBar = bottomTabs.any { it.route == currentRoute }
    val contextualTitle = toolTitle(currentRoute)
    val isToolRoute = contextualTitle != null
    val screenTitle = tabTitle(currentRoute)

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            when {
                currentRoute == AppDestination.Onboarding.route -> Unit
                isToolRoute -> {
                    TopAppBar(
                        title = {
                            Text(contextualTitle.orEmpty(), maxLines = 1, overflow = TextOverflow.Ellipsis)
                        },
                        navigationIcon = {
                            IconButton(onClick = { navController.popBackStack() }) {
                                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                            }
                        },
                        colors = AppTopAppBarDefaults.toolColors(),
                        actions = {
                            when (currentRoute) {
                                AppDestination.PayCalendar.route -> {
                                    IconButton(onClick = { payCalendarAddRequest = true }) {
                                        Icon(Icons.Default.Add, contentDescription = "Add special pay")
                                    }
                                }
                                AppDestination.PfraScore.route, AppDestination.PfraGoals.route -> {
                                    IconButton(onClick = { navController.navigate(AppDestination.PfraRecords.route) }) {
                                        Icon(Icons.Default.BarChart, contentDescription = "Records")
                                    }
                                }
                            }
                        },
                    )
                }
                screenTitle != null -> {
                    CenterAlignedTopAppBar(
                        title = { Text(screenTitle, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                        colors = AppTopAppBarDefaults.centerAlignedColors(),
                    )
                }
            }
        },
        bottomBar = {
            if (showBottomBar) {
                NavigationBar(
                    containerColor = MaterialTheme.colorScheme.surfaceContainer,
                    contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                ) {
                    tabs.forEach { tab ->
                        val selected = currentRoute == tab.destination.route
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                navController.navigate(tab.destination.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(tab.icon, contentDescription = tab.label) },
                            label = { Text(tab.label) },
                            colors = AppNavigationDefaults.navigationBarItemColors(),
                        )
                    }
                }
            }
        },
    ) { padding ->
        NavHost(navController = navController, startDestination = AppDestination.Home.route) {
            composable(AppDestination.Home.route) {
                HomeScreen(
                    onPickBase = {
                        navController.navigate(AppDestination.Menu.route) {
                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    onOpenTool = { appState.openTool(it) },
                    onOpenExplore = { appState.openExplore() },
                    onOpenReminders = {
                        navController.navigate(AppDestination.Reminders.route) {
                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    showEmergencySheet = showEmergencyRequest,
                    onEmergencySheetDismiss = { appState.dismissEmergency() },
                    contentPadding = padding,
                )
            }
            composable(AppDestination.Explore.route) {
                ExploreScreen(onPickBase = { navController.navigate(AppDestination.Menu.route) }, contentPadding = padding)
            }
            composable(AppDestination.Assignment.route) {
                AssignmentScreen(
                    onPickBase = { navController.navigate(AppDestination.Menu.route) },
                    onOpenLeavePlanner = { navController.navigate(AppDestination.LeavePlanner.route) },
                    onOpenPfraGoals = { navController.navigate(AppDestination.PfraGoals.route) },
                    onOpenPfraScore = { navController.navigate(AppDestination.PfraScore.route) },
                    contentPadding = padding,
                )
            }
            composable(AppDestination.Reminders.route) {
                RemindersScreen(
                    onPickBase = { navController.navigate(AppDestination.Menu.route) },
                    onOpenPayCalendar = { navController.navigate(AppDestination.PayCalendar.route) },
                    onOpenWarTracker = { navController.navigate(AppDestination.WarTracker.route) },
                    contentPadding = padding,
                )
            }
            composable(AppDestination.Menu.route) {
                MenuScreen(
                    onPickBase = { showBasePicker = true },
                    onFeedback = { navController.navigate(AppDestination.Feedback.route) },
                    onLegal = { navController.navigate(AppDestination.Legal.route) },
                    contentPadding = padding,
                )
            }
            composable(AppDestination.Onboarding.route) {
                OnboardingScreen(onFinished = {
                    showBasePicker = true
                    navController.navigate(AppDestination.Home.route) {
                        popUpTo(AppDestination.Onboarding.route) { inclusive = true }
                    }
                })
            }
            composable(AppDestination.PayCalendar.route) {
                PayCalendarScreen(
                    contentPadding = padding,
                    requestAdd = payCalendarAddRequest,
                    onAddHandled = { payCalendarAddRequest = false },
                )
            }
            composable(AppDestination.LeavePlanner.route) { LeavePlannerScreen(padding) }
            composable(AppDestination.PfraScore.route) { PfraScoreScreen(padding) }
            composable(AppDestination.PfraGoals.route) { PfraGoalsScreen(padding) }
            composable(AppDestination.PfraRecords.route) { PfraRecordsScreen(padding) }
            composable(AppDestination.WarTracker.route) { WarTrackerScreen(padding) }
            composable(AppDestination.AfiSearch.route) { AfiSearchScreen(padding) }
            composable(AppDestination.Feedback.route) { FeedbackScreen(padding) }
            composable(AppDestination.Legal.route) { LegalScreen(padding) }
        }
    }

    if (showBasePicker) {
        BasePickerSheet(
            onDismiss = { showBasePicker = false },
            onSelected = { id ->
                appState.selectBase(id)
                showBasePicker = false
            },
        )
    }

    if (showWarQuickLog) {
        val baseId = appState.currentBase.collectAsState().value?.id.orEmpty()
        WarQuickAddSheet(
            context = WarQuickAddContext(
                dateMillis = WarDateMath.startOfDay(System.currentTimeMillis()),
                locksDate = false,
                prefillBody = pendingWarText,
            ),
            onDismiss = { appState.dismissWarQuickLog() },
            onSave = { entry ->
                scope.launch {
                    if (baseId.isBlank()) return@launch
                    container.database.warDao().upsert(entry.copy(baseId = baseId))
                    appState.refreshNotifications(context)
                    appState.syncWidgets()
                    appState.dismissWarQuickLog()
                }
            },
        )
    }
}
