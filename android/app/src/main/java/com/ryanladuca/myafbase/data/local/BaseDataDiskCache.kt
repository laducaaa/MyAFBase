package com.ryanladuca.myafbase.data.local

import android.content.Context
import com.ryanladuca.myafbase.domain.logic.BaseCatalog
import java.io.File

class BaseDataDiskCache(context: Context) {
    private val root = File(context.filesDir, "base_cache").also { it.mkdirs() }

    fun readIndex(): String? = File(root, "bases_index.json").takeIf { it.exists() }?.readText()

    fun writeIndex(json: String) {
        File(root, "bases_index.json").writeText(json)
    }

    fun readBase(id: String): String? {
        val safe = BaseCatalog.sanitize(id) ?: return null
        return File(root, "$safe.json").takeIf { it.exists() }?.readText()
    }

    fun writeBase(id: String, json: String) {
        val safe = BaseCatalog.sanitize(id) ?: return
        File(root, "$safe.json").writeText(json)
    }

    fun indexLastModified(): Long = File(root, "bases_index.json").takeIf { it.exists() }?.lastModified() ?: 0L

    fun baseLastModified(id: String): Long {
        val safe = BaseCatalog.sanitize(id) ?: return 0L
        return File(root, "$safe.json").takeIf { it.exists() }?.lastModified() ?: 0L
    }
}
