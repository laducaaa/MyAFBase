package com.ryanladuca.myafbase.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.ryanladuca.myafbase.MyAFBaseApplication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class BootCompletedReceiver : BroadcastReceiver() {
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
    val app = context.applicationContext as? MyAFBaseApplication ?: return
    scope.launch {
      NotificationSync.refreshAll(context, app.container)
    }
  }
}
