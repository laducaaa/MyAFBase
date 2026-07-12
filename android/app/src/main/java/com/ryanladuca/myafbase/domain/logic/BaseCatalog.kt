package com.ryanladuca.myafbase.domain.logic

import com.ryanladuca.myafbase.domain.model.BaseIndexEntry
import java.util.Locale

object BaseCatalog {
    fun sanitize(id: String): String? {
        val trimmed = id.trim().lowercase(Locale.US)
        if (trimmed.isEmpty()) return null
        if (!trimmed.matches(Regex("^[a-z0-9]+(?:-[a-z0-9]+)*$"))) return null
        return trimmed
    }

    fun conusBases(index: List<BaseIndexEntry>): List<BaseIndexEntry> =
        index.filter { it.region.equals("conus", ignoreCase = true) }
            .sortedBy { it.name.lowercase(Locale.US) }

    fun isConus(entry: BaseIndexEntry): Boolean =
        entry.region.equals("conus", ignoreCase = true)
}
