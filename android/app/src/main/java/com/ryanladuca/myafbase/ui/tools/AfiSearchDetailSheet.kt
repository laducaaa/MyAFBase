package com.ryanladuca.myafbase.ui.tools

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
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
import com.ryanladuca.myafbase.data.afi.AfiSearchSnippet
import com.ryanladuca.myafbase.data.repository.AfiSearchResult
import com.ryanladuca.myafbase.domain.logic.EssentialAFIs
import com.ryanladuca.myafbase.ui.components.SheetDragHandle
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AfiSearchDetailSheet(
    result: AfiSearchResult,
    query: String,
    onDismiss: () -> Unit,
    onOpenPdf: (AfiPdfPreviewContext) -> Unit,
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val chunk = result.chunk
    val hasBundled = EssentialAFIs.bundledAssetPath(chunk.publicationId) != null

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        dragHandle = { SheetDragHandle() },
        containerColor = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(horizontal = AppTokens.screenPadding)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                chunk.title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                buildString {
                    append(chunk.publication)
                    chunk.section?.takeIf { it.isNotBlank() }?.let { append(" · $it") }
                    if (chunk.page > 0) append(" · Page ${chunk.page}")
                },
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Text(
                text = AfiSearchSnippet.highlight(
                    chunk.text,
                    query,
                    MaterialTheme.colorScheme.primary,
                ),
                style = MaterialTheme.typography.bodyMedium,
                lineHeight = MaterialTheme.typography.bodyMedium.lineHeight * 1.2,
            )

            Text(
                "Passages are extracted automatically. Always verify against the official publication before acting on guidance.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            HorizontalDivider()

            if (hasBundled) {
                Button(
                    onClick = {
                        onOpenPdf(
                            AfiPdfPreviewContext(
                                publicationId = chunk.publicationId,
                                title = chunk.publication,
                                page = chunk.page.takeIf { it > 0 },
                                passageText = chunk.text,
                                highlightQuery = query,
                            ),
                        )
                        onDismiss()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = AppButtonDefaults.primary(),
                ) {
                    Icon(Icons.Default.PictureAsPdf, contentDescription = null)
                    Text(
                        if (chunk.page > 0) "View PDF · p. ${chunk.page}" else "View PDF",
                        modifier = Modifier.padding(start = 8.dp),
                    )
                }
            } else {
                EssentialAFIs.findByPublicationId(chunk.publicationId)?.fallbackUrl?.let { fallback ->
                    TextButton(
                        onClick = {
                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(fallback)))
                        },
                    ) {
                        Text("Open official PDF")
                    }
                }
            }

            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text("Close")
            }
        }
    }
}
