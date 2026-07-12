package com.ryanladuca.myafbase.data.prefs

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore("myafbase_prefs")

data class WarNotificationSettings(
    val memberType: String = "enlisted",
    val dailyNudgeEnabled: Boolean = false,
    val dailyNudgeHour: Int = 20,
    val weeklyReminderEnabled: Boolean = false,
    val weeklyReminderWeekday: Int = 6,
    val weeklyReminderHour: Int = 15,
    val autoDeleteEnabled: Boolean = false,
    val autoDeleteAfterYears: Int = 3,
)

class UserPreferences(private val context: Context) {
    private val selectedBaseIdKey = stringPreferencesKey("selected_base_id")
    private val onboardingKey = booleanPreferencesKey("has_completed_onboarding")
    private val weatherEnabledKey = booleanPreferencesKey("weather_enabled")
    private val remindersEnabledKey = booleanPreferencesKey("readiness_reminders_enabled")
    private val warLockedKey = booleanPreferencesKey("war_locked")
    private val legalAckKey = booleanPreferencesKey("legal_acknowledged")
    private val dismissedRemindersKey = stringSetPreferencesKey("dismissed_reminder_ids")
    private val warMemberTypeKey = stringPreferencesKey("war_member_type")
    private val warDailyNudgeKey = booleanPreferencesKey("war_daily_nudge_enabled")
    private val warDailyNudgeHourKey = intPreferencesKey("war_daily_nudge_hour")
    private val warWeeklyReminderKey = booleanPreferencesKey("war_weekly_reminder_enabled")
    private val warWeeklyWeekdayKey = intPreferencesKey("war_weekly_reminder_weekday")
    private val warWeeklyHourKey = intPreferencesKey("war_weekly_reminder_hour")
    private val warAutoDeleteKey = booleanPreferencesKey("war_auto_delete_enabled")
    private val warAutoDeleteYearsKey = intPreferencesKey("war_auto_delete_after_years")

    val selectedBaseId: Flow<String?> = context.dataStore.data.map { it[selectedBaseIdKey] }
    val hasCompletedOnboarding: Flow<Boolean> = context.dataStore.data.map { it[onboardingKey] ?: false }
    val weatherEnabled: Flow<Boolean> = context.dataStore.data.map { it[weatherEnabledKey] ?: true }
    val remindersEnabled: Flow<Boolean> = context.dataStore.data.map { it[remindersEnabledKey] ?: false }
    val warLocked: Flow<Boolean> = context.dataStore.data.map { it[warLockedKey] ?: false }
    val dismissedReminderIds: Flow<Set<String>> = context.dataStore.data.map { it[dismissedRemindersKey] ?: emptySet() }

    suspend fun setSelectedBaseId(id: String?) {
        context.dataStore.edit { prefs ->
            if (id.isNullOrBlank()) prefs.remove(selectedBaseIdKey) else prefs[selectedBaseIdKey] = id
        }
    }

    suspend fun setOnboardingCompleted(value: Boolean) {
        context.dataStore.edit { it[onboardingKey] = value }
    }

    suspend fun setWeatherEnabled(value: Boolean) {
        context.dataStore.edit { it[weatherEnabledKey] = value }
    }

    suspend fun setRemindersEnabled(value: Boolean) {
        context.dataStore.edit { it[remindersEnabledKey] = value }
    }

    suspend fun setWarLocked(value: Boolean) {
        context.dataStore.edit { it[warLockedKey] = value }
    }

    suspend fun setLegalAcknowledged(value: Boolean) {
        context.dataStore.edit { it[legalAckKey] = value }
    }

    suspend fun dismissReminder(id: String) {
        context.dataStore.edit { prefs ->
            val current = prefs[dismissedRemindersKey] ?: emptySet()
            prefs[dismissedRemindersKey] = current + id
        }
    }

    suspend fun clearDismissedReminders() {
        context.dataStore.edit { it.remove(dismissedRemindersKey) }
    }

    suspend fun dismissAllReminders(ids: Set<String>) {
        context.dataStore.edit { prefs ->
            val current = prefs[dismissedRemindersKey] ?: emptySet()
            prefs[dismissedRemindersKey] = current + ids
        }
    }

    suspend fun warNotificationSettings(): WarNotificationSettings {
        val prefs = context.dataStore.data.first()
        return WarNotificationSettings(
            memberType = prefs[warMemberTypeKey] ?: "enlisted",
            dailyNudgeEnabled = prefs[warDailyNudgeKey] ?: false,
            dailyNudgeHour = prefs[warDailyNudgeHourKey] ?: 20,
            weeklyReminderEnabled = prefs[warWeeklyReminderKey] ?: false,
            weeklyReminderWeekday = prefs[warWeeklyWeekdayKey] ?: 6,
            weeklyReminderHour = prefs[warWeeklyHourKey] ?: 15,
            autoDeleteEnabled = prefs[warAutoDeleteKey] ?: false,
            autoDeleteAfterYears = prefs[warAutoDeleteYearsKey] ?: 3,
        )
    }

    suspend fun setWarMemberType(value: String) {
        context.dataStore.edit { it[warMemberTypeKey] = value }
    }

    suspend fun setWarDailyNudgeEnabled(value: Boolean) {
        context.dataStore.edit { it[warDailyNudgeKey] = value }
    }

    suspend fun setWarDailyNudgeHour(value: Int) {
        context.dataStore.edit { it[warDailyNudgeHourKey] = value }
    }

    suspend fun setWarWeeklyReminderEnabled(value: Boolean) {
        context.dataStore.edit { it[warWeeklyReminderKey] = value }
    }

    suspend fun setWarWeeklyReminderWeekday(value: Int) {
        context.dataStore.edit { it[warWeeklyWeekdayKey] = value }
    }

    suspend fun setWarWeeklyReminderHour(value: Int) {
        context.dataStore.edit { it[warWeeklyHourKey] = value }
    }

    suspend fun setWarAutoDeleteEnabled(value: Boolean) {
        context.dataStore.edit { it[warAutoDeleteKey] = value }
    }

    suspend fun setWarAutoDeleteAfterYears(value: Int) {
        context.dataStore.edit { it[warAutoDeleteYearsKey] = value }
    }
}
