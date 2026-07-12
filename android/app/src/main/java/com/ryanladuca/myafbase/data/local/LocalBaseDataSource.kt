package com.ryanladuca.myafbase.data.local

import android.content.Context
import com.ryanladuca.myafbase.domain.logic.BaseCatalog
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.BaseIndexEntry
import kotlinx.serialization.json.Json

class LocalBaseDataSource(
    private val context: Context,
    private val json: Json
) {
    fun loadIndex(): List<BaseIndexEntry> {
        val text = context.assets.open("bases/bases_index.json").bufferedReader().use { it.readText() }
        return json.decodeFromString<List<BaseIndexEntry>>(text)
    }

    fun loadBase(id: String): Base? {
        val safe = BaseCatalog.sanitize(id) ?: return null
        return runCatching {
            val text = context.assets.open("bases/$safe.json").bufferedReader().use { it.readText() }
            json.decodeFromString<Base>(text)
        }.getOrNull()
    }
}
