package com.ryanladuca.myafbase.widget

import kotlinx.serialization.Serializable

@Serializable
data class PayWidgetUpcomingItem(
    val title: String,
    val dateMillis: Long,
    val daysUntil: Int,
    val isSpecial: Boolean,
    val symbolName: String,
) {
    val daysLabel: String
        get() = when (daysUntil) {
            0 -> "Today"
            1 -> "1 day"
            else -> "$daysUntil days"
        }
}

@Serializable
data class PayWidgetSnapshot(
    val nextTitle: String,
    val nextDateMillis: Long,
    val daysUntil: Int,
    val isSpecial: Boolean,
    val symbolName: String,
    val upcoming: List<PayWidgetUpcomingItem>,
    val updatedAtMillis: Long,
) {
    val isAvailable: Boolean get() = nextTitle.isNotEmpty()

    val daysLabel: String
        get() = when (daysUntil) {
            0 -> "Today"
            1 -> "Tomorrow"
            else -> "In $daysUntil days"
        }
}

@Serializable
data class WeatherWidgetSnapshot(
    val baseId: String,
    val baseName: String,
    val location: String?,
    val tempF: Int?,
    val feelsLikeF: Int?,
    val conditionName: String,
    val symbolName: String,
    val windMph: Int?,
    val humidity: Int?,
    val isAvailable: Boolean,
    val updatedAtMillis: Long,
) {
    val tempDisplay: String get() = tempF?.let { "$it°" } ?: "—"
}

@Serializable
data class OpenNowWidgetItemSnapshot(
    val id: String,
    val name: String,
    val categoryLabel: String,
    val systemImage: String,
    val detail: String?,
    val statusLabel: String = "Open",
    val isOpen: Boolean = true,
)

@Serializable
data class OpenNowWidgetSnapshot(
    val baseId: String,
    val baseName: String,
    val items: List<OpenNowWidgetItemSnapshot>,
    val bookmarks: List<OpenNowWidgetItemSnapshot>,
    val updatedAtMillis: Long,
) {
    val openCount: Int get() = items.size

    val summaryText: String
        get() = when (openCount) {
            0 -> "Nothing open right now"
            1 -> "1 place open"
            else -> "$openCount places open"
        }
}

@Serializable
data class EmergencyContactSnapshot(
    val id: String,
    val label: String,
    val number: String,
    val systemImage: String,
    val isUniversalEmergency: Boolean,
)

@Serializable
data class EmergencyWidgetSnapshot(
    val baseId: String,
    val baseName: String,
    val contacts: List<EmergencyContactSnapshot>,
    val updatedAtMillis: Long,
)

@Serializable
data class ReadinessWidgetItemSnapshot(
    val kind: String,
    val title: String,
    val systemImage: String,
    val countdownValue: Int?,
    val countdownLabel: String,
    val detailLabel: String,
    val statusRaw: String,
)

@Serializable
data class ReadinessWidgetSnapshot(
    val activeBaseId: String,
    val activeBaseName: String,
    val items: List<ReadinessWidgetItemSnapshot>,
    val updatedAtMillis: Long,
)

@Serializable
data class WarWidgetSnapshot(
    val baseId: String,
    val entriesThisWeek: Int,
    val weekRangeLabel: String,
    val updatedAtMillis: Long,
)
