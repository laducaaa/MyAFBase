package com.ryanladuca.myafbase.ui.tools

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.afi.AfiMatchKind
import com.ryanladuca.myafbase.data.afi.AfiSearchSnippet
import com.ryanladuca.myafbase.data.repository.AfiSearchResult
import com.ryanladuca.myafbase.domain.logic.EssentialAFIs
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.components.M3SurfaceCard
import com.ryanladuca.myafbase.ui.components.SectionCard
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val exampleQueries = listOf(
    "uniform", "PT", "leave", "alcohol", "social media", "dress", "fitness",
)

@Composable
fun AfiSearchScreen(contentPadding: PaddingValues) {
    val container = LocalAppContainer.current
    val context = LocalContext.current
    val repository = container.afiSearchRepository

    var query by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<AfiSearchResult>>(emptyList()) }
    var selected by remember { mutableStateOf<AfiSearchResult?>(null) }
    var pdfPreview by remember { mutableStateOf<AfiPdfPreviewContext?>(null) }
    val scope = rememberCoroutineScope()

    val isIndexing by repository.isIndexing.collectAsState()
    val indexProgress by repository.indexProgress.collectAsState()
    val backfillProgress by repository.semanticBackfillProgress.collectAsState()
    val isReady by repository.isReady.collectAsState()
    val preparationFailure by repository.preparationFailure.collectAsState()

    LaunchedEffect(Unit) {
        repository.ensureLoaded()
    }

    LaunchedEffect(query, isReady) {
        val trimmed = query.trim()
        if (!isReady || trimmed.length < 2) {
            results = emptyList()
            return@LaunchedEffect
        }
        delay(250)
        results = repository.search(trimmed)
    }

    pdfPreview?.let { preview ->
        AfiPdfViewerScreen(context = preview, onDismiss = { pdfPreview = null })
        return
    }

    selected?.let { result ->
        AfiSearchDetailSheet(
            result = result,
            query = query,
            onDismiss = { selected = null },
            onOpenPdf = { pdfPreview = it },
        )
    }

    M3FlatScreenBackground {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding)
                .padding(horizontal = AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
            contentPadding = PaddingValues(bottom = 32.dp),
        ) {
            item {
                Text(
                    "Search Essential AFIs offline with citations to the official PDFs.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            item {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    modifier = Modifier.fillMaxWidth(),
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    placeholder = { Text(if (isReady) "Search AFI guidance" else "Preparing offline search…") },
                    enabled = isReady || isIndexing,
                    singleLine = true,
                    shape = AppTextFieldDefaults.shape,
                    colors = AppTextFieldDefaults.colors(),
                )
            }

            when {
                isIndexing -> item {
                    IndexingCard(progress = indexProgress)
                }
                preparationFailure != null && !isReady -> item {
                    StatusCard(
                        title = preparationFailure!!.title,
                        message = preparationFailure!!.message,
                        actionLabel = "Try Again",
                        onAction = { scope.launch { repository.retryPreparation() } },
                    )
                }
                query.trim().length >= 2 -> {
                    if (results.isEmpty()) {
                        item {
                            StatusCard(
                                title = if (isReady) "No results" else "Still getting ready",
                                message = if (isReady) {
                                    "Try shorter keywords, a publication number, or browse Essential AFIs below."
                                } else {
                                    "Offline search is still setting up. Give it a moment, then try again."
                                },
                                actionLabel = if (isReady) null else "Try Again",
                                onAction = if (isReady) null else {
                                    { scope.launch { repository.retryPreparation() } }
                                },
                            )
                        }
                    } else {
                        item {
                            Text(
                                "${results.size} result${if (results.size == 1) "" else "s"}",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                        items(results, key = { it.chunk.id }) { result ->
                            SearchResultCard(
                                result = result,
                                query = query,
                                onShowDetail = { selected = result },
                                onOpenPdf = {
                                    pdfPreview = AfiPdfPreviewContext(
                                        publicationId = result.chunk.publicationId,
                                        title = result.chunk.publication,
                                        page = result.chunk.page.takeIf { it > 0 },
                                        passageText = result.chunk.text,
                                        highlightQuery = query,
                                    )
                                },
                            )
                        }
                    }
                }
                isReady -> {
                    item {
                        M3SurfaceCard {
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text(
                                    "Ready for offline search",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.SemiBold,
                                )
                                Text(
                                    "Search by topic, policy phrase, or publication. Results include the matched passage and a jump to the cited PDF page.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                        }
                    }
                    backfillProgress?.let { progress ->
                        item {
                            Text(
                                "Improving related matches… ${(progress * 100).toInt()}%",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.secondary,
                            )
                        }
                    }
                    item {
                        Text("Try a search", style = MaterialTheme.typography.titleSmall)
                        Row(
                            modifier = Modifier.horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            exampleQueries.forEach { q ->
                                FilterChip(
                                    selected = false,
                                    onClick = { query = q },
                                    label = { Text(q) },
                                    colors = AppChipDefaults.filterChip(selected = false),
                                )
                            }
                        }
                    }
                    item { Text("Quick access", style = MaterialTheme.typography.titleSmall) }
                    items(EssentialAFIs.stationed, key = { it.id }) { afi ->
                        SectionCard(
                            title = afi.publication,
                            subtitle = afi.title,
                            onClick = {
                                if (EssentialAFIs.bundledAssetPath(afi.id) != null) {
                                    pdfPreview = AfiPdfPreviewContext(afi.id, afi.publication, page = 1)
                                } else {
                                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(afi.fallbackUrl)))
                                }
                            },
                        )
                    }
                }
                else -> item {
                    StatusCard(
                        title = "Preparing offline search",
                        message = "One-time setup builds a local index so you can search Essential AFIs without a network connection.",
                        actionLabel = null,
                        onAction = null,
                    )
                }
            }

            item {
                Text(
                    "Search results are extracted automatically and may be incomplete. Always verify against the official PDF.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun IndexingCard(progress: Double) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircularProgressIndicator(modifier = Modifier.padding(4.dp))
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        "Preparing offline search",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        "Building the local search index…",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            LinearProgressIndicator(progress = { progress.toFloat() }, modifier = Modifier.fillMaxWidth())
            Text(
                "${(progress * 100).toInt()}%",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.primary,
            )
        }
    }
}

@Composable
private fun StatusCard(
    title: String,
    message: String,
    actionLabel: String?,
    onAction: (() -> Unit)?,
) {
    M3SurfaceCard {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            Text(message, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            if (actionLabel != null && onAction != null) {
                TextButton(onClick = onAction, colors = AppButtonDefaults.text()) {
                    Text(actionLabel)
                }
            }
        }
    }
}

@Composable
private fun SearchResultCard(
    result: AfiSearchResult,
    query: String,
    onShowDetail: () -> Unit,
    onOpenPdf: () -> Unit,
) {
    val chunk = result.chunk
    val hasBundled = EssentialAFIs.bundledAssetPath(chunk.publicationId) != null

    SectionCard(
        title = chunk.publication,
        subtitle = buildString {
            chunk.section?.takeIf { it.isNotBlank() }?.let { append("$it · ") }
            append(chunk.title)
            if (chunk.page > 0) append(" · p.${chunk.page}")
            append(" · ${matchLabel(result.matchKind)}")
        },
        onClick = onShowDetail,
    ) {
        Text(
            text = AfiSearchSnippet.highlightedExcerpt(
                chunk.text,
                query,
                MaterialTheme.colorScheme.primary,
            ),
            style = MaterialTheme.typography.bodyMedium,
            maxLines = 6,
        )
        if (hasBundled) {
            TextButton(onClick = onOpenPdf) {
                Icon(Icons.Default.PictureAsPdf, contentDescription = null)
                Text(
                    if (chunk.page > 0) "View PDF · p. ${chunk.page}" else "View PDF",
                    modifier = Modifier.padding(start = 6.dp),
                )
            }
        }
    }
}

private fun matchLabel(kind: AfiMatchKind): String = when (kind) {
    AfiMatchKind.KEYWORD -> "Keyword"
    AfiMatchKind.SEMANTIC -> "Related"
    AfiMatchKind.BOTH -> "Keyword + Related"
}
