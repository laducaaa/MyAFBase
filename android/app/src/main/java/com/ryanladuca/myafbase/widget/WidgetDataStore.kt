package com.ryanladuca.myafbase.widget

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

private val Context.widgetDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "widget_snapshots",
)

class WidgetDataStore(
    private val context: Context,
    private val json: Json = Json { ignoreUnknownKeys = true },
) {
    private val readinessKey = stringPreferencesKey("readiness")
    private val weatherKey = stringPreferencesKey("weather")
    private val openNowKey = stringPreferencesKey("open_now")
    private val emergencyKey = stringPreferencesKey("emergency")
    private val payKey = stringPreferencesKey("pay")
    private val warTrackerKey = stringPreferencesKey("war_tracker")

    suspend fun saveReadiness(snapshot: ReadinessWidgetSnapshot) = save(readinessKey, snapshot)
    suspend fun saveWeather(snapshot: WeatherWidgetSnapshot) = save(weatherKey, snapshot)
    suspend fun saveOpenNow(snapshot: OpenNowWidgetSnapshot) = save(openNowKey, snapshot)
    suspend fun saveEmergency(snapshot: EmergencyWidgetSnapshot) = save(emergencyKey, snapshot)
    suspend fun savePay(snapshot: PayWidgetSnapshot) = save(payKey, snapshot)
    suspend fun saveWarTracker(snapshot: WarWidgetSnapshot) = save(warTrackerKey, snapshot)

    suspend fun loadReadiness(): ReadinessWidgetSnapshot? = load(readinessKey)
    suspend fun loadWeather(): WeatherWidgetSnapshot? = load(weatherKey)
    suspend fun loadOpenNow(): OpenNowWidgetSnapshot? = load(openNowKey)
    suspend fun loadEmergency(): EmergencyWidgetSnapshot? = load(emergencyKey)
    suspend fun loadPay(): PayWidgetSnapshot? = load(payKey)
    suspend fun loadWarTracker(): WarWidgetSnapshot? = load(warTrackerKey)

    fun observePay() = context.widgetDataStore.data.map { prefs ->
        prefs[payKey]?.let { decode<PayWidgetSnapshot>(it) }
    }

    private suspend inline fun <reified T> save(key: Preferences.Key<String>, value: T) {
        context.widgetDataStore.edit { prefs ->
            prefs[key] = json.encodeToString(value)
        }
    }

    private suspend inline fun <reified T> load(key: Preferences.Key<String>): T? {
        val raw = context.widgetDataStore.data.first()[key] ?: return null
        return decode(raw)
    }

    private inline fun <reified T> decode(raw: String): T? =
        runCatching { json.decodeFromString<T>(raw) }.getOrNull()
}
