package com.ryanladuca.myafbase

import android.content.Intent
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.compose.runtime.CompositionLocalProvider
import androidx.fragment.app.FragmentActivity
import com.ryanladuca.myafbase.notifications.NotificationIntents
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.MyAFBaseApp
import com.ryanladuca.myafbase.ui.theme.MyAFBaseTheme

class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = application as MyAFBaseApplication
        handleDeepLinkIntent(intent, app)
        setContent {
            CompositionLocalProvider(
                LocalAppContainer provides app.container,
                LocalAppState provides app.container.appState
            ) {
                MyAFBaseTheme {
                    MyAFBaseApp()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLinkIntent(intent, application as MyAFBaseApplication)
    }

    private fun handleDeepLinkIntent(intent: Intent?, app: MyAFBaseApplication) {
        if (intent == null) return
        val state = app.container.appState
        when (intent.getStringExtra(NotificationIntents.EXTRA_TARGET_TAB)) {
            NotificationIntents.TAB_REMINDERS -> state.openReminders()
            NotificationIntents.TAB_ASSIGNMENT -> state.openAssignment()
            NotificationIntents.TAB_HOME -> state.openHome()
            NotificationIntents.TAB_EXPLORE -> state.openExplore()
        }
        intent.getStringExtra(NotificationIntents.EXTRA_TARGET_TOOL)?.let { state.openTool(it) }
        if (intent.getBooleanExtra(NotificationIntents.EXTRA_SHOW_EMERGENCY, false)) {
            state.requestShowEmergency()
        }
        if (intent.getBooleanExtra(NotificationIntents.EXTRA_WAR_QUICK_LOG, false)) {
            val text = intent.getStringExtra(NotificationIntents.EXTRA_WAR_QUICK_LOG_TEXT)
            state.requestWarQuickLog(text)
        }
        intent.removeExtra(NotificationIntents.EXTRA_TARGET_TAB)
        intent.removeExtra(NotificationIntents.EXTRA_TARGET_TOOL)
        intent.removeExtra(NotificationIntents.EXTRA_SHOW_EMERGENCY)
        intent.removeExtra(NotificationIntents.EXTRA_WAR_QUICK_LOG)
        intent.removeExtra(NotificationIntents.EXTRA_WAR_QUICK_LOG_TEXT)
    }
}
