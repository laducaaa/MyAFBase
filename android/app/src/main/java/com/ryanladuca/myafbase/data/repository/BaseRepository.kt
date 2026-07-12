package com.ryanladuca.myafbase.data.repository

import com.ryanladuca.myafbase.data.BaseDataRemoteConfig
import com.ryanladuca.myafbase.data.local.BaseDataDiskCache
import com.ryanladuca.myafbase.data.local.LocalBaseDataSource
import com.ryanladuca.myafbase.data.remote.RemoteBaseDataSource
import com.ryanladuca.myafbase.domain.logic.BaseCatalog
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.BaseIndexEntry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

class BaseRepository(
    private val local: LocalBaseDataSource,
    private val remote: RemoteBaseDataSource,
    private val cache: BaseDataDiskCache,
    private val json: Json
) {
    suspend fun getIndex(forceRemote: Boolean = false): List<BaseIndexEntry> = withContext(Dispatchers.IO) {
        if (forceRemote || shouldRefreshIndex()) {
            remote.fetchIndex()?.let { payload ->
                cache.writeIndex(payload)
                return@withContext json.decodeFromString<List<BaseIndexEntry>>(payload)
            }
        }
        cache.readIndex()?.let { return@withContext json.decodeFromString<List<BaseIndexEntry>>(it) }
        local.loadIndex()
    }

    suspend fun getBase(id: String, forceRemote: Boolean = false): Base? = withContext(Dispatchers.IO) {
        val safe = BaseCatalog.sanitize(id) ?: return@withContext null
        if (forceRemote || shouldRefreshBase(safe)) {
            remote.fetchBase(safe)?.let { payload ->
                cache.writeBase(safe, payload)
                return@withContext json.decodeFromString<Base>(payload)
            }
        }
        cache.readBase(safe)?.let { return@withContext json.decodeFromString<Base>(it) }
        local.loadBase(safe)
    }

    suspend fun syncIfNeeded(selectedBaseId: String?): List<BaseIndexEntry> {
        val index = getIndex(forceRemote = shouldRefreshIndex())
        selectedBaseId?.let { getBase(it, forceRemote = shouldRefreshBase(it)) }
        return index
    }

    suspend fun refreshAll(selectedBaseId: String?): Pair<List<BaseIndexEntry>, Base?> {
        val index = getIndex(forceRemote = true)
        val base = selectedBaseId?.let { getBase(it, forceRemote = true) }
        return index to base
    }

    private fun shouldRefreshIndex(): Boolean {
        val age = System.currentTimeMillis() - cache.indexLastModified()
        return cache.indexLastModified() == 0L || age > BaseDataRemoteConfig.INDEX_REFRESH_INTERVAL_MS
    }

    private fun shouldRefreshBase(id: String): Boolean {
        val age = System.currentTimeMillis() - cache.baseLastModified(id)
        return cache.baseLastModified(id) == 0L || age > BaseDataRemoteConfig.BASE_REFRESH_INTERVAL_MS
    }
}
