package com.ryanladuca.myafbase.ui.tools

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import com.ryanladuca.myafbase.data.afi.AfiSearchSnippet
import com.ryanladuca.myafbase.domain.logic.EssentialAFIs
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class AfiPdfPreviewContext(
    val publicationId: String,
    val title: String,
    val page: Int?,
    val passageText: String? = null,
    val highlightQuery: String? = null,
)

fun resolveBundledPdfFile(context: Context, publicationId: String): File? {
    val assetPath = EssentialAFIs.bundledAssetPath(publicationId) ?: return null
    val outFile = File(context.cacheDir, "afi-$publicationId.pdf")
    if (!outFile.exists() || outFile.length() == 0L) {
        runCatching {
            context.assets.open(assetPath).use { input ->
                outFile.outputStream().use { output -> input.copyTo(output) }
            }
        }.getOrElse { return null }
    }
    return outFile
}

private data class PdfPageRender(
    val pageIndex: Int,
    val bitmap: Bitmap,
)

private suspend fun openPdfRenderer(file: File): Pair<PdfRenderer, Int> = withContext(Dispatchers.IO) {
    val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    val renderer = PdfRenderer(pfd)
    renderer to renderer.pageCount
}

private suspend fun renderPdfPage(
    renderer: PdfRenderer,
    pageIndex: Int,
    targetWidthPx: Int,
): Bitmap? = withContext(Dispatchers.IO) {
    if (renderer.pageCount <= 0) return@withContext null
    val index = pageIndex.coerceIn(0, renderer.pageCount - 1)
    renderer.openPage(index).use { page ->
        val scale = targetWidthPx.toFloat() / page.width.toFloat()
        val width = (page.width * scale).toInt().coerceAtLeast(1)
        val height = (page.height * scale).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        bitmap
    }
}

private fun sharePdf(context: Context, file: File, title: String) {
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "application/pdf"
        putExtra(Intent.EXTRA_STREAM, uri)
        putExtra(Intent.EXTRA_SUBJECT, title)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(intent, "Share PDF"))
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AfiPdfViewerScreen(
    context: AfiPdfPreviewContext,
    onDismiss: () -> Unit,
) {
    val androidContext = LocalContext.current
    val density = LocalDensity.current
    val targetWidthPx = remember(density) { with(density) { 360.dp.roundToPx() } }

    var pdfFile by remember { mutableStateOf<File?>(null) }
    var renderer by remember { mutableStateOf<PdfRenderer?>(null) }
    var pageCount by remember { mutableStateOf(0) }
    var copying by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    val renderedPages = remember { mutableStateMapOf<Int, Bitmap>() }
    val listState = rememberLazyListState(
        initialFirstVisibleItemIndex = ((context.page ?: 1) - 1).coerceAtLeast(0),
    )

    val excerpt = remember(context.passageText, context.highlightQuery) {
        val text = context.passageText.orEmpty()
        val query = context.highlightQuery.orEmpty()
        if (text.isBlank()) null
        else if (query.isBlank()) text.take(360)
        else AfiSearchSnippet.excerpt(text, query)
    }

    LaunchedEffect(context.publicationId) {
        copying = true
        error = null
        renderedPages.values.forEach { it.recycle() }
        renderedPages.clear()
        renderer?.close()
        renderer = null

        val file = withContext(Dispatchers.IO) {
            resolveBundledPdfFile(androidContext, context.publicationId)
        }
        copying = false
        if (file == null) {
            error = "PDF not available offline."
            return@LaunchedEffect
        }
        pdfFile = file
        runCatching {
            val (opened, count) = openPdfRenderer(file)
            renderer = opened
            pageCount = count
            if (count <= 0) error = "PDF has no pages."
        }.onFailure {
            error = it.message ?: "Could not open PDF."
        }
    }

    LaunchedEffect(renderer, pageCount, listState.firstVisibleItemIndex) {
        val activeRenderer = renderer ?: return@LaunchedEffect
        if (pageCount <= 0) return@LaunchedEffect
        val visible = listState.firstVisibleItemIndex
        val pagesToRender = (visible - 1..visible + 2)
            .filter { it in 0 until pageCount }
        for (page in pagesToRender) {
            if (renderedPages.containsKey(page)) continue
            val bitmap = renderPdfPage(activeRenderer, page, targetWidthPx) ?: continue
            renderedPages[page]?.recycle()
            renderedPages[page] = bitmap
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            renderedPages.values.forEach { it.recycle() }
            renderedPages.clear()
            renderer?.close()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(context.title, maxLines = 1)
                        if (pageCount > 0) {
                            Text(
                                "${pageCount} page${if (pageCount == 1) "" else "s"}",
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Close")
                    }
                },
                actions = {
                    pdfFile?.let { file ->
                        IconButton(onClick = { sharePdf(androidContext, file, context.title) }) {
                            Icon(Icons.Default.Share, contentDescription = "Share PDF")
                        }
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            if (copying) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                Text(
                    "Preparing PDF…",
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    style = MaterialTheme.typography.bodySmall,
                )
            }

            excerpt?.let { passage ->
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        "Matched passage",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary,
                    )
                    val query = context.highlightQuery.orEmpty()
                    Text(
                        text = if (query.isNotBlank()) {
                            AfiSearchSnippet.highlight(
                                passage,
                                query,
                                MaterialTheme.colorScheme.primary,
                            )
                        } else {
                            androidx.compose.ui.text.AnnotatedString(passage)
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    context.page?.takeIf { it > 0 }?.let { page ->
                        Text(
                            "Jumped to page $page",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                HorizontalDivider()
            }

            when {
                error != null -> Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(error!!, modifier = Modifier.padding(24.dp))
                }
                pageCount <= 0 && !copying -> Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center,
                ) {
                    CircularProgressIndicator()
                }
                else -> PdfPagesList(
                    pageCount = pageCount,
                    renderedPages = renderedPages,
                    listState = listState,
                    targetPage = (context.page ?: 1) - 1,
                )
            }
        }
    }
}

@Composable
private fun PdfPagesList(
    pageCount: Int,
    renderedPages: Map<Int, Bitmap>,
    listState: LazyListState,
    targetPage: Int,
) {
    LaunchedEffect(pageCount, targetPage) {
        if (pageCount > 0) {
            listState.scrollToItem(targetPage.coerceIn(0, pageCount - 1))
        }
    }

    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        items((0 until pageCount).toList(), key = { it }) { pageIndex ->
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    "Page ${pageIndex + 1}",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                val bitmap = renderedPages[pageIndex]
                if (bitmap != null) {
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = "PDF page ${pageIndex + 1}",
                        modifier = Modifier.fillMaxWidth(),
                        contentScale = ContentScale.FillWidth,
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 48.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        CircularProgressIndicator()
                    }
                }
            }
        }
    }
}
