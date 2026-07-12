package com.ryanladuca.myafbase.data.repository

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

@Serializable
data class FeedbackPayload(
    val category: String,
    val message: String,
    val appVersion: String,
    val baseID: String? = null,
    val baseName: String? = null,
    val deviceModel: String,
    val platform: String = "android",
    val osVersion: String? = null,
    val contactEmail: String? = null,
    val contactEmailConsent: Boolean = false
)

class FeedbackRepository(
    private val client: OkHttpClient = OkHttpClient(),
    private val json: Json = Json { encodeDefaults = true }
) {
    companion object {
        const val ENDPOINT = "https://myafbase-feedback.rladuca92.workers.dev"
        const val MIN_MESSAGE = 12
        const val MAX_MESSAGE = 4000
    }

    suspend fun submit(payload: FeedbackPayload): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val body = json.encodeToString(payload)
                .toRequestBody("application/json; charset=utf-8".toMediaType())
            val request = Request.Builder().url(ENDPOINT).post(body).build()
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) error("Feedback failed (${response.code})")
            }
        }
    }
}
