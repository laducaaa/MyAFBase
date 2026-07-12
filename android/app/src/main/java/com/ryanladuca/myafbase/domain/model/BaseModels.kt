package com.ryanladuca.myafbase.domain.model

import kotlinx.serialization.Serializable

@Serializable
data class BaseIndexEntry(
    val id: String,
    val name: String,
    val location: String,
    val wing: String,
    val region: String
)

@Serializable
data class EmergencyNumber(
    val id: String,
    val label: String,
    val number: String
)

@Serializable
data class NotificationItem(
    val id: String,
    val title: String,
    val body: String,
    val type: String = "alert",
    val postedAt: String? = null,
    val expiresAt: String? = null
)

@Serializable
data class Gate(
    val id: String,
    val name: String,
    val status: String = "unknown",
    val hours: String = "",
    val notes: String? = null,
    val traffic: String = "unknown",
    val address: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null
)

@Serializable
data class Resource(
    val id: String,
    val slug: String? = null,
    val name: String,
    val category: String = "other",
    val description: String? = null,
    val hours: String? = null,
    val address: String? = null,
    val phone: String? = null,
    val url: String? = null,
    val building: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val type: String? = null,
    val value: String? = null
) {
    val displayHours: String?
        get() = hours?.takeIf { it.isNotBlank() }
            ?: value?.takeIf { type == "hours" && it.isNotBlank() }

    val displayAddress: String?
        get() = address?.takeIf { it.isNotBlank() }
            ?: building?.takeIf { it.isNotBlank() }
            ?: value?.takeIf { type == "location" && it.isNotBlank() }

    val displayPhone: String?
        get() = phone?.takeIf { it.isNotBlank() }
            ?: value?.takeIf { type == "phone" && it.isNotBlank() }

    val displayURL: String?
        get() = url?.takeIf { it.isNotBlank() }
            ?: value?.takeIf { type == "url" && it.isNotBlank() }
}

@Serializable
data class Event(
    val id: String,
    val title: String,
    val date: String? = null,
    val endDate: String? = null,
    val location: String = "",
    val address: String? = null,
    val description: String = "",
    val category: String? = null
) {
    val displayAddress: String?
        get() = address?.takeIf { it.isNotBlank() } ?: location.takeIf { it.isNotBlank() }
}

@Serializable
data class NewcomerLink(
    val id: String,
    val title: String,
    val url: String
)

@Serializable
data class NewcomerSection(
    val id: String,
    val title: String,
    val body: String,
    val links: List<NewcomerLink>? = null,
    val icon: String? = null
)

@Serializable
data class NewcomerPrimaryAction(
    val title: String,
    val url: String? = null,
    val phone: String? = null,
    val address: String? = null
)

@Serializable
data class NewcomersInfo(
    val primaryAction: NewcomerPrimaryAction? = null,
    val moreInfoURL: String? = null,
    val sections: List<NewcomerSection> = emptyList()
)

@Serializable
data class Base(
    val id: String,
    val name: String,
    val fullName: String = "",
    val location: String = "",
    val description: String = "",
    val wing: String = "",
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val dataUpdatedAt: String? = null,
    val currentNotifications: List<NotificationItem> = emptyList(),
    val emergencyNumbers: List<EmergencyNumber> = emptyList(),
    val gates: List<Gate> = emptyList(),
    val resources: List<Resource> = emptyList(),
    val events: List<Event> = emptyList(),
    val newcomers: NewcomersInfo = NewcomersInfo()
)

enum class BookmarkTargetType(val raw: String) {
    GATE("gate"),
    RESOURCE("resource"),
    EVENT("event");

    companion object {
        fun fromRaw(value: String): BookmarkTargetType =
            entries.firstOrNull { it.raw == value } ?: RESOURCE
    }
}
