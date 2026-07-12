package com.ryanladuca.myafbase.ui.navigation

sealed class AppDestination(val route: String) {
    data object Home : AppDestination("home")
    data object Explore : AppDestination("explore")
    data object Assignment : AppDestination("assignment")
    data object Reminders : AppDestination("reminders")
    data object Menu : AppDestination("menu")
    data object Onboarding : AppDestination("onboarding")
    data object BasePicker : AppDestination("base_picker")
    data object PayCalendar : AppDestination("tool_pay")
    data object LeavePlanner : AppDestination("tool_leave")
    data object PfraScore : AppDestination("tool_pfra")
    data object PfraGoals : AppDestination("tool_pfra_goals")
    data object PfraRecords : AppDestination("tool_pfra_records")
    data object WarTracker : AppDestination("tool_war")
    data object AfiSearch : AppDestination("tool_afi")
    data object Feedback : AppDestination("feedback")
    data object Legal : AppDestination("legal")
    data object ExploreMap : AppDestination("explore_map")
}

val bottomTabs = listOf(
    AppDestination.Home,
    AppDestination.Explore,
    AppDestination.Assignment,
    AppDestination.Reminders,
    AppDestination.Menu
)
