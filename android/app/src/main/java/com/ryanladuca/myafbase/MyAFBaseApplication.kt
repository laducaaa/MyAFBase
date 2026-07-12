package com.ryanladuca.myafbase

import android.app.Application
import android.os.Build
import com.google.android.material.color.DynamicColors
import com.ryanladuca.myafbase.data.AppContainer
import com.ryanladuca.myafbase.notifications.NotificationChannels
import com.ryanladuca.myafbase.notifications.NotificationSync
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class MyAFBaseApplication : Application() {
    lateinit var container: AppContainer
        private set

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            DynamicColors.applyToActivitiesIfAvailable(this)
        }
        container = AppContainer(this)
        NotificationChannels.ensureAll(this)
        scope.launch {
            NotificationSync.refreshAll(this@MyAFBaseApplication, container)
            container.appState.syncWidgets()
            container.afiSearchRepository.ensureLoaded()
        }
    }
}
