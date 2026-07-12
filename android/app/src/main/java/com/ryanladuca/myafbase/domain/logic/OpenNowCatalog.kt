package com.ryanladuca.myafbase.domain.logic

import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.Gate
import com.ryanladuca.myafbase.domain.model.Resource

data class OpenNowEntry(
    val id: String,
    val name: String,
    val kind: Kind,
    val detail: String?,
) {
    enum class Kind { GATE, DINING, FITNESS, MEDICAL, OTHER }

    val categoryLabel: String
        get() = when (kind) {
            Kind.GATE -> "Gate"
            Kind.DINING -> "Dining"
            Kind.FITNESS -> "Fitness"
            Kind.MEDICAL -> "Medical"
            Kind.OTHER -> "Resource"
        }

    val systemImage: String
        get() = when (kind) {
            Kind.GATE -> "gate"
            Kind.DINING -> "dining"
            Kind.FITNESS -> "fitness"
            Kind.MEDICAL -> "medical"
            Kind.OTHER -> "resource"
        }
}

object OpenNowCatalog {
    private val featuredCategories = setOf("dining", "fitness", "medical")

    fun openEntries(
        base: Base,
        resourceLimit: Int = 5,
        gateLimit: Int = 3,
    ): List<OpenNowEntry> {
        val entries = mutableListOf<OpenNowEntry>()
        for (resource in openResources(base, resourceLimit)) {
            entries += OpenNowEntry(
                id = "resource-${resource.id}",
                name = resource.name,
                kind = resourceKind(resource.category),
                detail = todayHoursSummary(resource.displayHours),
            )
        }
        for (gate in openGates(base, gateLimit)) {
            entries += OpenNowEntry(
                id = "gate-${gate.id}",
                name = gate.name,
                kind = OpenNowEntry.Kind.GATE,
                detail = todayHoursSummary(gate.hours),
            )
        }
        return entries.sortedBy { it.name.lowercase() }
    }

    fun openResources(base: Base, limit: Int? = null): List<Resource> {
        val matches = base.resources
            .filter { featuredCategories.contains(it.category.lowercase()) && isResourceOpen(it) }
            .sortedBy { it.name.lowercase() }
        return if (limit != null) matches.take(limit) else matches
    }

    fun openGates(base: Base, limit: Int? = null): List<Gate> {
        val matches = base.gates
            .filter { isGateOpen(it) }
            .sortedBy { it.name.lowercase() }
        return if (limit != null) matches.take(limit) else matches
    }

    private fun isResourceOpen(resource: Resource): Boolean {
        val hours = resource.displayHours ?: return false
        return HoursParser.isOpenNow(hours) == true
    }

    private fun isGateOpen(gate: Gate): Boolean {
        if (gate.status.equals("closed", ignoreCase = true)) return false
        val hours = gate.hours.takeIf { it.isNotBlank() } ?: return gate.status.equals("open", ignoreCase = true)
        return HoursParser.isOpenNow(hours) == true
    }

    private fun resourceKind(category: String): OpenNowEntry.Kind = when (category.lowercase()) {
        "dining" -> OpenNowEntry.Kind.DINING
        "fitness" -> OpenNowEntry.Kind.FITNESS
        "medical" -> OpenNowEntry.Kind.MEDICAL
        else -> OpenNowEntry.Kind.OTHER
    }

    private fun todayHoursSummary(hours: String?): String? {
        if (hours.isNullOrBlank()) return null
        val parsed = HoursParser.parse(hours)
        return parsed.todayHoursText ?: parsed.fallbackText
    }
}
