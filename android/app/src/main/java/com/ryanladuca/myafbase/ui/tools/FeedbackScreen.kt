package com.ryanladuca.myafbase.ui.tools

import android.os.Build
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.BuildConfig
import com.ryanladuca.myafbase.data.repository.FeedbackPayload
import com.ryanladuca.myafbase.data.repository.FeedbackRepository
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.AppScreenBackground
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppCheckboxDefaults
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch

private data class FeedbackCat(
    val id: String,
    val title: String,
    val placeholder: String,
)

private val categories = listOf(
    FeedbackCat("bug", "Bug", "What went wrong? Include steps to reproduce if you can."),
    FeedbackCat("feature", "Idea", "What would you like the app to do?"),
    FeedbackCat("baseData", "Base Data", "Which base, resource, or hours are incorrect?"),
    FeedbackCat("general", "Other", "Share your thoughts — we're listening."),
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedbackScreen(contentPadding: PaddingValues) {
    val appState = LocalAppState.current
    val container = LocalAppContainer.current
    val base by appState.currentBase.collectAsState()
    var category by remember { mutableStateOf(categories.first()) }
    var categoryExpanded by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var consent by remember { mutableStateOf(false) }
    var success by remember { mutableStateOf(false) }
    var status by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    if (success) {
        AppScreenBackground {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(contentPadding)
                    .padding(AppTokens.screenPadding),
                verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Thanks", style = MaterialTheme.typography.headlineSmall)
                Text(
                    "Your feedback was sent. We read every submission.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Button(
                    onClick = {
                        success = false
                        message = ""
                        email = ""
                        consent = false
                        status = null
                    },
                    colors = AppButtonDefaults.primary(),
                ) { Text("Send another") }
            }
        }
        return
    }

    AppScreenBackground {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding)
                .padding(AppTokens.screenPadding)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(AppTokens.sectionSpacing),
        ) {
            Text(
                "Help improve MyAFBase. Don't include PII, names, orders, or sensitive details.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            ExposedDropdownMenuBox(
                expanded = categoryExpanded,
                onExpandedChange = { categoryExpanded = it },
            ) {
                OutlinedTextField(
                    value = category.title,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Category") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                    modifier = Modifier
                        .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                        .fillMaxWidth(),
                    shape = AppTextFieldDefaults.shape,
                    colors = AppTextFieldDefaults.colors(),
                )
                ExposedDropdownMenu(
                    expanded = categoryExpanded,
                    onDismissRequest = { categoryExpanded = false },
                ) {
                    categories.forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option.title) },
                            onClick = {
                                category = option
                                categoryExpanded = false
                            },
                        )
                    }
                }
            }

            OutlinedTextField(
                value = message,
                onValueChange = { message = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Message") },
                placeholder = { Text(category.placeholder) },
                minLines = 6,
                supportingText = {
                    Text("${message.trim().length} / ${FeedbackRepository.MAX_MESSAGE}")
                },
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )

            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Reply email (optional)") },
                singleLine = true,
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )

            if (email.isNotBlank()) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Checkbox(
                        checked = consent,
                        onCheckedChange = { consent = it },
                        colors = AppCheckboxDefaults.colors(),
                    )
                    Text(
                        "OK to contact me about this feedback.",
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f),
                    )
                }
            }

            Text(
                "Feedback is sent to our worker and may become a GitHub issue.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Button(
                enabled = message.trim().length in FeedbackRepository.MIN_MESSAGE..FeedbackRepository.MAX_MESSAGE &&
                    (email.isBlank() || consent),
                modifier = Modifier.fillMaxWidth(),
                colors = AppButtonDefaults.primary(),
                onClick = {
                    scope.launch {
                        status = "Sending…"
                        val result = container.feedbackRepository.submit(
                            FeedbackPayload(
                                category = category.id,
                                message = message.trim(),
                                appVersion = BuildConfig.VERSION_NAME,
                                baseID = base?.id,
                                baseName = base?.name,
                                deviceModel = "${Build.MANUFACTURER} ${Build.MODEL}",
                                platform = "android",
                                osVersion = "Android ${Build.VERSION.RELEASE}",
                                contactEmail = email.ifBlank { null },
                                contactEmailConsent = consent && email.isNotBlank(),
                            ),
                        )
                        result.fold(
                            onSuccess = {
                                success = true
                                status = null
                            },
                            onFailure = { status = "Failed: ${it.message}" },
                        )
                    }
                },
            ) { Text("Submit feedback") }

            status?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
