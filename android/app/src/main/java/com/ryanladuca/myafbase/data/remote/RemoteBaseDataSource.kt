package com.ryanladuca.myafbase.data.remote

import com.ryanladuca.myafbase.data.BaseDataRemoteConfig
import com.ryanladuca.myafbase.domain.logic.BaseCatalog
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

class RemoteBaseDataSource(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()
) {
    fun fetchIndex(): String? = fetch(BaseDataRemoteConfig.indexUrl)

    fun fetchBase(id: String): String? {
        val safe = BaseCatalog.sanitize(id) ?: return null
        return fetch(BaseDataRemoteConfig.baseUrl(safe))
    }

    private fun fetch(url: String): String? = runCatching {
        val request = Request.Builder().url(url).get().build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) return null
            response.body?.string()
        }
    }.getOrNull()
}
