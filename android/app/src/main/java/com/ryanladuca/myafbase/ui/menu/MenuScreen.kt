package com.ryanladuca.myafbase.ui.menu

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.BuildConfig
import com.ryanladuca.myafbase.domain.model.AssignmentSegment
import com.ryanladuca.myafbase.notifications.NotificationPermission
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.AppAlertDialog
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.components.SectionHeader
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppSwitchDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.utils.AppReleaseNotes
import com.ryanladuca.myafbase.utils.ContactConfig
import kotlinx.coroutines.launch

private data class MenuLink(val title: String, val url: String)

private val quickLinks = listOf(
    MenuLink("ICE Surveys", "https://ice.disa.mil/"),
    MenuLink("AF OSI", "https://www.osi.af.mil/Submit-a-Tip/"),
    MenuLink("DEERS/ID", "https://www.cac.mil/"),
    MenuLink("MyGenesis", "https://my.mhsgenesis.health.mil/"),
    MenuLink("Tricare", "https://www.tricare.mil/"),
    MenuLink("MyVector", "https://myvector.us.af.mil/"),
    MenuLink("vMPF", "https://www.my.af.mil/"),
    MenuLink("Move.mil (TMO)", "https://www.move.mil/"),
)

@Composable
fun MenuScreen(
    onPickBase: () -> Unit,
    onFeedback: () -> Unit,
    onLegal: () -> Unit,
    contentPadding: PaddingValues,
) {
    val appState = LocalAppState.current
    val container = LocalAppContainer.current
    val base by appState.currentBase.collectAsState()
    val indexEntry = appState.selectedIndexEntry()
    val weatherEnabled by appState.weatherEnabled.collectAsState()
    val remindersEnabled by appState.remindersEnabled.collectAsState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var showClearBookmarks by remember { mutableStateOf(false) }
    var showWhatsNew by remember { mutableStateOf(false) }
    val scheme = MaterialTheme.colorScheme
    var pendingRemindersToggle by remember { mutableStateOf(false) }

    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        appState.onNotificationPermissionResult(granted, context)
        if (granted && pendingRemindersToggle) {
            appState.setRemindersEnabled(true, context)
        }
        pendingRemindersToggle = false
    }

    fun requestRemindersEnabled(enabled: Boolean) {
        if (!enabled) {
            appState.setRemindersEnabled(false, context)
            return
        }
        if (NotificationPermission.isGranted(context)) {
            appState.setRemindersEnabled(true, context)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pendingRemindersToggle = true
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            appState.setRemindersEnabled(true, context)
        }
    }

    fun openUrl(url: String) {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }

    if (showWhatsNew) WhatsNewSheet(onDismiss = { showWhatsNew = false })

    if (showClearBookmarks) {
        AppAlertDialog(
            title = "Clear all bookmarks?",
            text = "This removes all saved gates, resources, and events on this device. This cannot be undone.",
            onDismiss = { showClearBookmarks = false },
            confirmText = "Clear",
            onConfirm = {
                scope.launch {
                    container.database.bookmarkDao().deleteAll()
                    showClearBookmarks = false
                }
            },
        )
    }

    M3FlatScreenBackground {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding),
            contentPadding = PaddingValues(AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                MenuGroupedSection(title = "Installation") {
                    MenuBaseListItem(
                        baseName = base?.name,
                        wing = base?.wing,
                        location = base?.location,
                        dataUpdatedAt = base?.dataUpdatedAt,
                        onClick = onPickBase,
                    )
                    base?.let { b ->
                        HorizontalDivider(
                            modifier = Modifier.padding(horizontal = 16.dp),
                            color = scheme.outlineVariant,
                        )
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                        ) {
                            MenuInstallationPhaseSection(baseId = b.id)
                        }
                    }
                }
            }

            item {
                MenuGroupedSection(title = "Quick Links") {
                    quickLinks.forEachIndexed { index, link ->
                        MenuLinkListItem(
                            title = link.title,
                            icon = Icons.AutoMirrored.Filled.OpenInNew,
                            onClick = { openUrl(link.url) },
                        )
                        if (index < quickLinks.lastIndex) {
                            HorizontalDivider(
                                modifier = Modifier.padding(horizontal = 16.dp),
                                color = scheme.outlineVariant,
                            )
                        }
                    }
                }
            }

            item {
                MenuGroupedSection(title = "Preferences") {
                    MenuSwitchListItem(
                        title = "Show weather on Home",
                        checked = weatherEnabled,
                        onCheckedChange = { appState.setWeatherEnabled(it) },
                    )
                    if (indexEntry?.region == "oconus") {
                        Text(
                            "Weather is hidden for OCONUS bases when disabled.",
                            style = MaterialTheme.typography.bodySmall,
                            color = scheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                        )
                    }
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        color = scheme.outlineVariant,
                    )
                    MenuSwitchListItem(
                        title = "Readiness reminders",
                        checked = remindersEnabled,
                        onCheckedChange = { requestRemindersEnabled(it) },
                    )
                    TextButton(
                        onClick = { showClearBookmarks = true },
                        colors = AppButtonDefaults.text(),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    ) {
                        Text("Clear all bookmarks", color = scheme.error)
                    }
                }
            }

            item {
                MenuGroupedSection(title = "Support") {
                    MenuLinkListItem(
                        title = "Send feedback",
                        icon = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        onClick = onFeedback,
                    )
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        color = scheme.outlineVariant,
                    )
                    MenuLinkListItem(
                        title = "Email support",
                        icon = Icons.AutoMirrored.Filled.OpenInNew,
                        onClick = {
                            context.startActivity(
                                Intent(Intent.ACTION_SENDTO, Uri.parse(ContactConfig.supportMailtoUrl)),
                            )
                        },
                    )
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        color = scheme.outlineVariant,
                    )
                    MenuLinkListItem(
                        title = "Support website",
                        icon = Icons.AutoMirrored.Filled.OpenInNew,
                        onClick = { openUrl(ContactConfig.SUPPORT_URL) },
                    )
                }
            }

            item {
                MenuGroupedSection(title = "Legal") {
                    MenuLinkListItem(
                        title = "Legal & privacy",
                        icon = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        onClick = onLegal,
                    )
                }
            }

            item {
                MenuGroupedSection(title = "About") {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { showWhatsNew = true }
                            .padding(horizontal = 20.dp, vertical = 20.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Text(
                            "MyAFBase for Android",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Surface(
                            shape = MaterialTheme.shapes.small,
                            color = scheme.secondaryContainer,
                            tonalElevation = 0.dp,
                        ) {
                            Text(
                                "Version ${BuildConfig.VERSION_NAME}",
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelMedium,
                                color = scheme.onSecondaryContainer,
                                fontWeight = FontWeight.SemiBold,
                            )
                        }
                        Text(
                            AppReleaseNotes.current.title,
                            style = MaterialTheme.typography.bodyMedium,
                            color = scheme.onSurfaceVariant,
                        )
                        Text(
                            "Independent community tool. Not affiliated with the DoD or U.S. Air Force.",
                            style = MaterialTheme.typography.bodySmall,
                            color = scheme.onSurfaceVariant,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MenuGroupedSection(
    title: String,
    content: @Composable () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionHeader(title = title)
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.extraLarge,
            color = scheme.surfaceContainerHigh,
            tonalElevation = 1.dp,
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                content()
            }
        }
    }
}

@Composable
private fun MenuBaseListItem(
    baseName: String?,
    wing: String?,
    location: String?,
    dataUpdatedAt: String?,
    onClick: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = ListItemDefaults.colors(containerColor = scheme.surfaceContainerHigh),
        leadingContent = {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = scheme.primaryContainer,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    Icons.Default.Place,
                    contentDescription = null,
                    tint = scheme.onPrimaryContainer,
                    modifier = Modifier
                        .padding(10.dp)
                        .size(20.dp),
                )
            }
        },
        headlineContent = {
            Text(
                baseName ?: "Select Base",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
            )
        },
        supportingContent = {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    when {
                        baseName != null -> "$wing · $location"
                        else -> "Tap to choose your installation"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = scheme.onSurfaceVariant,
                )
                dataUpdatedAt?.let { updated ->
                    Text(
                        "Data updated $updated",
                        style = MaterialTheme.typography.bodySmall,
                        color = scheme.onSurfaceVariant,
                    )
                }
            }
        },
        trailingContent = {
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = scheme.onSurfaceVariant,
            )
        },
    )
}

@Composable
private fun MenuLinkListItem(
    title: String,
    icon: ImageVector,
    onClick: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = ListItemDefaults.colors(containerColor = scheme.surfaceContainerHigh),
        headlineContent = {
            Text(title, style = MaterialTheme.typography.bodyLarge)
        },
        trailingContent = {
            Icon(icon, contentDescription = null, tint = scheme.onSurfaceVariant)
        },
    )
}

@Composable
private fun MenuSwitchListItem(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    ListItem(
        colors = ListItemDefaults.colors(containerColor = scheme.surfaceContainerHigh),
        headlineContent = {
            Text(title, style = MaterialTheme.typography.bodyLarge)
        },
        trailingContent = {
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                colors = AppSwitchDefaults.colors(),
            )
        },
    )
}

@Composable
private fun MenuInstallationPhaseSection(baseId: String) {
    val container = LocalAppContainer.current
    val profile by container.database.assignmentDao().observe(baseId).collectAsState(initial = null)
    val phase = AssignmentSegment.fromRaw(profile?.phaseRaw)
    MenuAssignmentPhaseRow(baseId = baseId, phase = phase) { }
}
