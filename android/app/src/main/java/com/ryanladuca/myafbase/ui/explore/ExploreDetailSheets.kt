package com.ryanladuca.myafbase.ui.explore

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
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
import com.ryanladuca.myafbase.domain.logic.HoursParser
import com.ryanladuca.myafbase.domain.model.Event
import com.ryanladuca.myafbase.domain.model.Gate
import com.ryanladuca.myafbase.domain.model.Resource
import com.ryanladuca.myafbase.ui.components.SheetDragHandle
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens

sealed class ExploreDetailTarget {
    data class GateItem(val gate: Gate) : ExploreDetailTarget()
    data class ResourceItem(val resource: Resource) : ExploreDetailTarget()
    data class EventItem(val event: Event) : ExploreDetailTarget()
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LocationDetailSheet(
    title: String,
    hours: String?,
    address: String?,
    phone: String?,
    url: String?,
    description: String?,
    gateStatus: String? = null,
    traffic: String? = null,
    onOpenMaps: (() -> Unit)? = null,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        dragHandle = { SheetDragHandle() },
        containerColor = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AppTokens.screenPadding)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            gateStatus?.let {
                DetailRow("Status", it.replaceFirstChar { ch -> ch.uppercase() })
            }
            traffic?.takeIf { it.isNotBlank() && !it.equals("unknown", ignoreCase = true) }?.let {
                DetailRow("Traffic", it.replaceFirstChar { ch -> ch.uppercase() })
            }
            hours?.takeIf { it.isNotBlank() }?.let { rawHours ->
                DetailRow("Hours", HoursParser.cardDisplay(rawHours))
            }
            address?.takeIf { it.isNotBlank() }?.let {
                DetailRow("Address", it)
            }
            phone?.takeIf { it.isNotBlank() }?.let {
                DetailRow("Phone", it, onClick = {
                    context.startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$it")))
                })
            }
            url?.takeIf { it.isNotBlank() }?.let {
                DetailRow("Website", it, onClick = {
                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(it)))
                })
            }
            description?.takeIf { it.isNotBlank() }?.let {
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                Text("Details", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Text(it, style = MaterialTheme.typography.bodyMedium)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                onOpenMaps?.let { maps ->
                    Button(onClick = maps, colors = AppButtonDefaults.primary()) {
                        Text("Directions")
                    }
                }
                TextButton(onClick = onDismiss, colors = AppButtonDefaults.textNeutral()) {
                    Text("Close")
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventDetailSheet(
    event: Event,
    onOpenMaps: (() -> Unit)? = null,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        dragHandle = { SheetDragHandle() },
        containerColor = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AppTokens.screenPadding)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            Text(event.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            event.date?.let { DetailRow("Date", it) }
            event.endDate?.takeIf { it.isNotBlank() }?.let { DetailRow("Ends", it) }
            if (event.location.isNotBlank()) DetailRow("Location", event.location)
            event.displayAddress?.let { DetailRow("Address", it) }
            if (event.description.isNotBlank()) {
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                Text("Details", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Text(event.description, style = MaterialTheme.typography.bodyMedium)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                onOpenMaps?.let {
                    Button(onClick = it, colors = AppButtonDefaults.primary()) { Text("Open in Maps") }
                }
                TextButton(onClick = onDismiss, colors = AppButtonDefaults.textNeutral()) { Text("Close") }
            }
        }
    }
}

@Composable
private fun DetailRow(label: String, value: String, onClick: (() -> Unit)? = null) {
    if (onClick != null) {
        TextButton(onClick = onClick, colors = AppButtonDefaults.text()) {
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(value, style = MaterialTheme.typography.bodyMedium)
            }
        }
    } else {
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, style = MaterialTheme.typography.bodyMedium)
        }
    }
}
