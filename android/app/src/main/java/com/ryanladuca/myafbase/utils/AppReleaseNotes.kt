package com.ryanladuca.myafbase.utils

data class AppReleaseHighlight(
    val title: String,
    val detail: String? = null,
)

data class AppReleaseNote(
    val version: String,
    val title: String,
    val highlights: List<AppReleaseHighlight>,
)

object AppReleaseNotes {
    val all: List<AppReleaseNote> = listOf(
        AppReleaseNote(
            version = "1.5.1",
            title = "Android launch parity",
            highlights = listOf(
                AppReleaseHighlight(
                    "PFRA Records",
                    "Save scores, compare past tests, and track trends over time.",
                ),
                AppReleaseHighlight(
                    "Notifications",
                    "Readiness reminders and WAR Tracker nudges with tap-to-open.",
                ),
                AppReleaseHighlight(
                    "WAR reports",
                    "Date presets, grouping, and plain-text or bullet export formats.",
                ),
                AppReleaseHighlight(
                    "Assignment newcomers",
                    "In-processing guides with links and report-and-arrive details.",
                ),
            ),
        ),
        AppReleaseNote(
            version = "1.0.0",
            title = "Android preview",
            highlights = listOf(
                AppReleaseHighlight("Home & Explore", "Weather hero, tools grid, gates, resources, and events."),
                AppReleaseHighlight("Assignment & readiness", "Phase-aware Assignment with key dates."),
                AppReleaseHighlight("PFRA tools", "Score calculator, goal planner, and records on device."),
            ),
        ),
    )

    val current: AppReleaseNote = all.first()
    val earlier: List<AppReleaseNote> = all.drop(1)
}
