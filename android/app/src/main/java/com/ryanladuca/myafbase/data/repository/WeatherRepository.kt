package com.ryanladuca.myafbase.data.repository

import com.ryanladuca.myafbase.domain.logic.WeatherCondition
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit
import kotlin.math.abs
import kotlin.math.roundToInt

data class WeatherSnapshot(
    val tempF: Double?,
    val feelsLikeF: Double?,
    val windMph: Double?,
    val humidity: Int?,
    val condition: WeatherCondition,
    val isDay: Boolean,
    val lastUpdatedMillis: Long = System.currentTimeMillis(),
) {
    val conditionLabel: String
        get() = if (isPlaceholder) "Unavailable" else condition.displayName

    val themeKey: String
        get() = if (isPlaceholder) "unknown" else condition.themeKey

    val isPlaceholder: Boolean
        get() = tempF == null && condition == WeatherCondition.Unknown

    fun feelsLikeDisplayF(): Int? {
        val feels = feelsLikeF ?: return null
        if (isPlaceholder) return null
        val rounded = feels.roundToInt()
        val actual = tempF?.roundToInt() ?: return rounded
        return if (abs(rounded - actual) >= 2) rounded else null
    }

    companion object {
        fun placeholder() = WeatherSnapshot(
            tempF = null,
            feelsLikeF = null,
            windMph = null,
            humidity = null,
            condition = WeatherCondition.Unknown,
            isDay = true,
        )
    }
}

class WeatherRepository(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .build(),
    private val json: Json = Json { ignoreUnknownKeys = true; isLenient = true },
) {
    private val cache = mutableMapOf<String, WeatherSnapshot>()
    private val cacheTtlMs = 15 * 60 * 1000L

    suspend fun fetch(lat: Double, lon: Double, forceRefresh: Boolean = false): WeatherSnapshot =
        withContext(Dispatchers.IO) {
            val key = "%.4f,%.4f".format(lat, lon)
            val cached = cache[key]
            if (!forceRefresh && cached != null &&
                System.currentTimeMillis() - cached.lastUpdatedMillis < cacheTtlMs
            ) {
                return@withContext cached
            }
            fetchOpenMeteo(lat, lon)?.also { cache[key] = it }
                ?: cached
                ?: WeatherSnapshot.placeholder()
        }

    private fun fetchOpenMeteo(lat: Double, lon: Double): WeatherSnapshot? = runCatching {
        val url =
            "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon" +
                "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m," +
                "relative_humidity_2m,is_day,precipitation,cloud_cover" +
                "&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&timezone=auto"
        val request = Request.Builder().url(url).get().build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) return null
            val body = response.body?.string() ?: return null
            val parsed = json.decodeFromString<OpenMeteoResponse>(body)
            val current = parsed.current ?: return null
            val cloudCover = current.cloudCover?.roundToInt()
            val condition = WeatherCondition.resolved(
                wmoCode = current.weatherCode ?: -1,
                cloudCoverPercent = cloudCover,
                precipitationInches = current.precipitation,
            )
            WeatherSnapshot(
                tempF = current.temperature2M,
                feelsLikeF = current.apparentTemperature,
                windMph = current.windSpeed10M,
                humidity = current.relativeHumidity2M,
                condition = condition,
                isDay = current.isDay == 1,
            )
        }
    }.getOrNull()

    @Serializable
    private data class OpenMeteoResponse(val current: OpenMeteoCurrent? = null)

    @Serializable
    private data class OpenMeteoCurrent(
        @SerialName("temperature_2m") val temperature2M: Double? = null,
        @SerialName("apparent_temperature") val apparentTemperature: Double? = null,
        @SerialName("weather_code") val weatherCode: Int? = null,
        @SerialName("wind_speed_10m") val windSpeed10M: Double? = null,
        @SerialName("relative_humidity_2m") val relativeHumidity2M: Int? = null,
        @SerialName("is_day") val isDay: Int? = null,
        @SerialName("precipitation") val precipitation: Double? = null,
        @SerialName("cloud_cover") val cloudCover: Double? = null,
    )
}
