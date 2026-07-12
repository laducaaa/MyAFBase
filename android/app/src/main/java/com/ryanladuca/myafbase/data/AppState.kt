package com.ryanladuca.myafbase.data

import android.content.Context
import com.ryanladuca.myafbase.data.db.AppDatabase
import com.ryanladuca.myafbase.data.prefs.UserPreferences
import com.ryanladuca.myafbase.data.repository.BaseRepository
import com.ryanladuca.myafbase.data.repository.WeatherRepository
import com.ryanladuca.myafbase.data.repository.WeatherSnapshot
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.BookmarkResolver
import com.ryanladuca.myafbase.widget.WidgetSync
import com.ryanladuca.myafbase.domain.model.BaseIndexEntry
import com.ryanladuca.myafbase.domain.model.BookmarkTargetType
import com.ryanladuca.myafbase.notifications.NotificationPermission
import com.ryanladuca.myafbase.notifications.NotificationSync
import com.ryanladuca.myafbase.notifications.ReadinessNotificationScheduler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class ExploreDestination(
    val segment: String = "resources", // resources | events
    val category: String? = null,
    val targetType: BookmarkTargetType? = null,
    val targetId: String? = null
)

class AppState(
    private val preferences: UserPreferences,
    private val baseRepository: BaseRepository,
    private val weatherRepository: WeatherRepository,
    private val widgetSync: WidgetSync,
    private val database: AppDatabase,
    private val appContext: Context,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    val selectedBaseId: StateFlow<String?> = preferences.selectedBaseId
        .stateIn(scope, SharingStarted.Eagerly, null)

    val hasCompletedOnboarding: StateFlow<Boolean> = preferences.hasCompletedOnboarding
        .stateIn(scope, SharingStarted.Eagerly, false)

    val weatherEnabled: StateFlow<Boolean> = preferences.weatherEnabled
        .stateIn(scope, SharingStarted.Eagerly, true)

    val remindersEnabled: StateFlow<Boolean> = preferences.remindersEnabled
        .stateIn(scope, SharingStarted.Eagerly, false)

    private val _index = MutableStateFlow<List<BaseIndexEntry>>(emptyList())
    val index: StateFlow<List<BaseIndexEntry>> = _index.asStateFlow()

    private val _currentBase = MutableStateFlow<Base?>(null)
    val currentBase: StateFlow<Base?> = _currentBase.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _pendingToolRoute = MutableStateFlow<String?>(null)
    val pendingToolRoute: StateFlow<String?> = _pendingToolRoute.asStateFlow()

    private val _pendingExploreDestination = MutableStateFlow<ExploreDestination?>(null)
    val pendingExploreDestination: StateFlow<ExploreDestination?> = _pendingExploreDestination.asStateFlow()

    private val _pendingTab = MutableStateFlow<String?>(null)
    val pendingTab: StateFlow<String?> = _pendingTab.asStateFlow()

    private val _pendingWarQuickLogText = MutableStateFlow<String?>(null)
    val pendingWarQuickLogText: StateFlow<String?> = _pendingWarQuickLogText.asStateFlow()

    private val _showWarQuickLog = MutableStateFlow(false)
    val showWarQuickLog: StateFlow<Boolean> = _showWarQuickLog.asStateFlow()

    private var lastWeatherSnapshot: WeatherSnapshot? = null

    init {
        scope.launch {
            selectedBaseId.collect { id ->
                if (id != null) {
                    _isLoading.value = true
                    _currentBase.value = baseRepository.getBase(id)
                    _isLoading.value = false
                    syncWidgets()
                } else {
                    _currentBase.value = null
                }
            }
        }
        scope.launch {
            _index.value = baseRepository.getIndex()
            baseRepository.syncIfNeeded(selectedBaseId.value)
            _index.value = baseRepository.getIndex()
            selectedBaseId.value?.let { _currentBase.value = baseRepository.getBase(it) }
            syncWidgets()
        }
    }

    fun syncWidgets(weather: WeatherSnapshot? = lastWeatherSnapshot) {
        scope.launch {
            val base = _currentBase.value ?: return@launch
            val baseId = base.id
            if (weather != null) lastWeatherSnapshot = weather
            val bookmarks = database.bookmarkDao().observeForBase(baseId).first()
            val resolved = BookmarkResolver.resolve(base, bookmarks)
            val specialPays = database.specialPayDao().observeAll().first()
            val warEntries = database.warDao().observeForBase(baseId).first()
            val readiness = database.readinessDao().get(baseId)
            widgetSync.publishAll(
                base = base,
                weather = lastWeatherSnapshot,
                readiness = readiness,
                bookmarks = resolved,
                specialPays = specialPays,
                warEntries = warEntries,
            )
        }
    }

    fun requestWarQuickLog(prefillText: String? = null) {
        _pendingWarQuickLogText.value = prefillText
        _showWarQuickLog.value = true
    }

    fun dismissWarQuickLog() {
        _showWarQuickLog.value = false
        _pendingWarQuickLogText.value = null
    }

    fun selectBase(id: String) {
        scope.launch {
            preferences.setSelectedBaseId(id)
            _isLoading.value = true
            _currentBase.value = baseRepository.getBase(id, forceRemote = false)
            _isLoading.value = false
        }
    }

    fun completeOnboarding() {
        scope.launch {
            preferences.setLegalAcknowledged(true)
            preferences.setOnboardingCompleted(true)
        }
    }

    fun setWeatherEnabled(enabled: Boolean) {
        scope.launch { preferences.setWeatherEnabled(enabled) }
    }

    fun setRemindersEnabled(enabled: Boolean, context: Context) {
        scope.launch {
            if (enabled && !NotificationPermission.isGranted(context)) {
                preferences.setRemindersEnabled(false)
                return@launch
            }
            preferences.setRemindersEnabled(enabled)
            if (!enabled) {
                val baseId = preferences.selectedBaseId.first()
                if (baseId != null) {
                    ReadinessNotificationScheduler.cancelForBase(context, baseId)
                }
            } else {
                refreshNotifications(context)
            }
        }
    }

    fun onNotificationPermissionResult(granted: Boolean, context: Context) {
        scope.launch {
            if (granted) {
                refreshNotifications(context)
            } else {
                preferences.setRemindersEnabled(false)
                preferences.setWarDailyNudgeEnabled(false)
                preferences.setWarWeeklyReminderEnabled(false)
            }
        }
    }

    fun refreshNotifications(context: Context) {
        scope.launch {
            val container = (context.applicationContext as com.ryanladuca.myafbase.MyAFBaseApplication).container
            NotificationSync.refreshAll(context, container)
        }
    }

    fun openAssignment() {
        _pendingTab.value = "assignment"
    }

    fun openHome() {
        _pendingTab.value = "home"
    }

    fun openReminders() {
        _pendingTab.value = "reminders"
    }

    private val _showEmergency = MutableStateFlow(false)
    val showEmergency: StateFlow<Boolean> = _showEmergency.asStateFlow()

    fun requestShowEmergency() {
        _pendingTab.value = "home"
        _showEmergency.value = true
    }

    fun dismissEmergency() {
        _showEmergency.value = false
    }

    fun refreshAll() {
        scope.launch {
            _isLoading.value = true
            val (index, base) = baseRepository.refreshAll(selectedBaseId.value)
            _index.value = index
            _currentBase.value = base
            _isLoading.value = false
            val weather = base?.let { b ->
                if (weatherEnabled.value) {
                    weatherRepository.fetch(b.latitude, b.longitude, forceRefresh = true)
                        .also { lastWeatherSnapshot = it }
                } else null
            }
            syncWidgets(weather)
        }
    }

    fun updateWeatherSnapshot(snapshot: WeatherSnapshot?) {
        lastWeatherSnapshot = snapshot
        syncWidgets(snapshot)
    }

    fun openTool(route: String) {
        _pendingToolRoute.value = route
    }

    fun consumeToolRoute() {
        _pendingToolRoute.value = null
    }

    fun openExplore(destination: ExploreDestination = ExploreDestination()) {
        _pendingExploreDestination.value = destination
        _pendingTab.value = "explore"
    }

    fun consumeExploreDestination(): ExploreDestination? {
        val value = _pendingExploreDestination.value
        _pendingExploreDestination.value = null
        return value
    }

    fun consumePendingTab(): String? {
        val value = _pendingTab.value
        _pendingTab.value = null
        return value
    }

    fun selectedIndexEntry(): BaseIndexEntry? =
        index.value.firstOrNull { it.id == selectedBaseId.value }
}
