package com.ryanladuca.myafbase.ui.menu

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.utils.ContactConfig

@Composable
fun LegalScreen(contentPadding: PaddingValues) {
    val context = LocalContext.current
    val scheme = MaterialTheme.colorScheme
    fun openUrl(url: String) {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }

    val sections = listOf(
        LegalSection(
            title = "Privacy policy",
            action = { openUrl(ContactConfig.PRIVACY_URL) },
            actionLabel = "myafbase.com/privacy",
        ),
        LegalSection(
            title = "Terms of use",
            action = { openUrl(ContactConfig.TERMS_URL) },
            actionLabel = "myafbase.com/terms",
        ),
        LegalSection(
            title = "Support",
            action = { openUrl(ContactConfig.SUPPORT_URL) },
            actionLabel = "myafbase.com/support",
        ),
        LegalSection(
            title = "Your Privacy Choices",
            action = { openUrl(ContactConfig.USER_CHOICES_URL) },
            actionLabel = "myafbase.com/user-choices",
        ),
        LegalSection(
            title = "Non-affiliation",
            body = "MyAFBase is an independent community tool. It is not affiliated with, endorsed by, or an official product of the Department of Defense or U.S. Air Force.",
        ),
        LegalSection(
            title = "Data on device",
            body = "Bookmarks, assignment dates, PFRA records, and WAR entries are stored locally on your device unless you choose to share feedback.",
        ),
    )

    M3FlatScreenBackground {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(contentPadding),
            contentPadding = PaddingValues(AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = MaterialTheme.shapes.extraLarge,
                    color = scheme.surfaceContainerHigh,
                    tonalElevation = 1.dp,
                ) {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        sections.forEachIndexed { index, section ->
                            LegalSectionContent(section = section)
                            if (index < sections.lastIndex) {
                                HorizontalDivider(
                                    modifier = Modifier.padding(horizontal = 16.dp),
                                    color = scheme.outlineVariant,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

private data class LegalSection(
    val title: String,
    val body: String? = null,
    val actionLabel: String? = null,
    val action: (() -> Unit)? = null,
)

@Composable
private fun LegalSectionContent(section: LegalSection) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(section.title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        section.body?.let {
            Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        section.action?.let { action ->
            TextButton(onClick = action, colors = AppButtonDefaults.text()) {
                Text(section.actionLabel.orEmpty())
            }
        }
    }
}
