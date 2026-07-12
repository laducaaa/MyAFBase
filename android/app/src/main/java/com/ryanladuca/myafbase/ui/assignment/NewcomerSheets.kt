package com.ryanladuca.myafbase.ui.assignment

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.model.NewcomerPrimaryAction
import com.ryanladuca.myafbase.domain.model.NewcomerSection
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewcomerSectionSheet(
    section: NewcomerSection,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = AppTokens.screenPadding)
                .padding(bottom = AppTokens.sectionSpacing),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            Text(section.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            Text(section.body, style = MaterialTheme.typography.bodyMedium)
            section.links.orEmpty().forEach { link ->
                TextButton(
                    onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(link.url))) },
                    colors = AppButtonDefaults.text(),
                ) { Text(link.title) }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewcomerPrimaryActionSheet(
    action: NewcomerPrimaryAction,
    baseName: String,
    latitude: Double,
    longitude: Double,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AppTokens.screenPadding)
                .padding(bottom = AppTokens.sectionSpacing),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            Text(action.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            action.address?.let {
                Text(it, style = MaterialTheme.typography.bodyMedium)
                TextButton(
                    onClick = {
                        val uri = Uri.parse("geo:$latitude,$longitude?q=${Uri.encode("$it ($baseName)")}")
                        context.startActivity(Intent(Intent.ACTION_VIEW, uri))
                    },
                    colors = AppButtonDefaults.text(),
                ) { Text("Open in Maps") }
            }
            action.phone?.let { phone ->
                TextButton(
                    onClick = {
                        context.startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone")))
                    },
                    colors = AppButtonDefaults.text(),
                ) { Text("Call $phone") }
            }
            action.url?.let { url ->
                TextButton(
                    onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) },
                    colors = AppButtonDefaults.text(),
                ) { Text("Open link") }
            }
        }
    }
}
