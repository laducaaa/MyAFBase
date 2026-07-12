package com.ryanladuca.myafbase.ui.home

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Directions
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.model.HomeSavedCategory
import com.ryanladuca.myafbase.domain.model.ResolvedBookmark
import com.ryanladuca.myafbase.ui.components.SectionHeader
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults

@Composable
fun HomeSavedSection(
    savedCategory: HomeSavedCategory,
    onCategorySelected: (HomeSavedCategory) -> Unit,
    items: List<ResolvedBookmark>,
    totalFilteredCount: Int,
    showTruncationHint: Boolean,
    onOpenExplore: () -> Unit,
    onOpenItem: (ResolvedBookmark) -> Unit,
    onUnbookmark: (ResolvedBookmark) -> Unit,
    onDirections: (ResolvedBookmark) -> Unit,
    onCall: (ResolvedBookmark) -> Unit,
    modifier: Modifier = Modifier,
) {
    val scheme = MaterialTheme.colorScheme

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SectionHeader(
            title = "Saved",
            prominent = true,
            primaryAction = if (totalFilteredCount > 0) "Explore" else null,
            onPrimaryAction = if (totalFilteredCount > 0) onOpenExplore else null,
        )

        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.extraLarge,
            color = scheme.surfaceContainerHigh,
            tonalElevation = 1.dp,
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    HomeSavedCategory.entries.forEach { category ->
                        FilterChip(
                            selected = savedCategory == category,
                            onClick = { onCategorySelected(category) },
                            label = { Text(category.label) },
                            leadingIcon = {
                                Icon(
                                    imageVector = category.icon(),
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp),
                                )
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = scheme.secondaryContainer,
                                selectedLabelColor = scheme.onSecondaryContainer,
                                selectedLeadingIconColor = scheme.onSecondaryContainer,
                            ),
                        )
                    }
                }

                HorizontalDivider(color = scheme.outlineVariant)

                if (items.isEmpty()) {
                    SavedEmptyState(
                        category = savedCategory,
                        onOpenExplore = onOpenExplore,
                    )
                } else {
                    items.forEachIndexed { index, item ->
                        SavedBookmarkListItem(
                            item = item,
                            onOpen = { onOpenItem(item) },
                            onUnbookmark = { onUnbookmark(item) },
                            onDirections = { onDirections(item) },
                            onCall = { onCall(item) },
                        )
                        if (index < items.lastIndex) {
                            HorizontalDivider(
                                modifier = Modifier.padding(horizontal = 16.dp),
                                color = scheme.outlineVariant,
                            )
                        }
                    }

                    if (showTruncationHint) {
                        HorizontalDivider(color = scheme.outlineVariant)
                        Text(
                            text = "Showing 10 of $totalFilteredCount. Open Explore for the rest.",
                            style = MaterialTheme.typography.bodySmall,
                            color = scheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SavedEmptyState(
    category: HomeSavedCategory,
    onOpenExplore: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val (title, body) = when (category) {
        HomeSavedCategory.ALL -> "Nothing saved yet" to "Bookmark gates, resources, or events in Explore to see them here."
        HomeSavedCategory.GATES -> "No saved gates" to "Bookmark installation gates in Explore to quick-launch directions from Home."
        HomeSavedCategory.RESOURCES -> "No saved resources" to "Bookmark dining, medical, and other resources from Explore."
        HomeSavedCategory.EVENTS -> "No saved events" to "Bookmark base events in Explore to find them quickly later."
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Surface(
            shape = MaterialTheme.shapes.large,
            color = scheme.primaryContainer,
            tonalElevation = 0.dp,
        ) {
            Icon(
                imageVector = Icons.Default.BookmarkBorder,
                contentDescription = null,
                tint = scheme.onPrimaryContainer,
                modifier = Modifier
                    .padding(14.dp)
                    .size(28.dp),
            )
        }
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = scheme.onSurface,
        )
        Text(
            text = body,
            style = MaterialTheme.typography.bodyMedium,
            color = scheme.onSurfaceVariant,
        )
        FilledTonalButton(onClick = onOpenExplore) {
            Icon(Icons.Default.Explore, contentDescription = null, modifier = Modifier.size(18.dp))
            Text("Open Explore", modifier = Modifier.padding(start = 8.dp))
        }
    }
}

@Composable
private fun SavedBookmarkListItem(
    item: ResolvedBookmark,
    onOpen: () -> Unit,
    onUnbookmark: () -> Unit,
    onDirections: () -> Unit,
    onCall: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val (icon, containerColor, contentColor) = savedItemStyle(item, scheme)

    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen),
        colors = ListItemDefaults.colors(containerColor = scheme.surfaceContainerHigh),
        headlineContent = {
            Text(
                text = item.title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        },
        supportingContent = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                item.subtitle?.takeIf { it.isNotBlank() }?.let { subtitle ->
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = scheme.onSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                val showCall = item is ResolvedBookmark.ResourceItem && item.resource.displayPhone != null
                val showDirections = item is ResolvedBookmark.GateItem || item is ResolvedBookmark.ResourceItem
                if (showCall || showDirections) {
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        if (showCall) {
                            TextButton(onClick = onCall, colors = AppButtonDefaults.text()) {
                                Icon(
                                    Icons.Default.Phone,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp),
                                )
                                Text("Call", modifier = Modifier.padding(start = 4.dp))
                            }
                        }
                        if (showDirections) {
                            TextButton(onClick = onDirections, colors = AppButtonDefaults.text()) {
                                Icon(
                                    Icons.Default.Directions,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp),
                                )
                                Text("Directions", modifier = Modifier.padding(start = 4.dp))
                            }
                        }
                    }
                }
            }
        },
        leadingContent = {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = containerColor,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = contentColor,
                    modifier = Modifier
                        .padding(10.dp)
                        .size(20.dp),
                )
            }
        },
        trailingContent = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onUnbookmark) {
                    Icon(
                        Icons.Default.Bookmark,
                        contentDescription = "Remove bookmark",
                        tint = scheme.primary,
                    )
                }
                IconButton(onClick = onOpen) {
                    Icon(
                        Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = "Open in Explore",
                        tint = scheme.onSurfaceVariant,
                    )
                }
            }
        },
    )
}

private fun HomeSavedCategory.icon(): ImageVector = when (this) {
    HomeSavedCategory.ALL -> Icons.Default.GridView
    HomeSavedCategory.GATES -> Icons.Default.DirectionsCar
    HomeSavedCategory.RESOURCES -> Icons.Default.Place
    HomeSavedCategory.EVENTS -> Icons.Default.CalendarMonth
}

@Composable
private fun savedItemStyle(
    item: ResolvedBookmark,
    scheme: androidx.compose.material3.ColorScheme,
): Triple<ImageVector, androidx.compose.ui.graphics.Color, androidx.compose.ui.graphics.Color> {
    return when (item) {
        is ResolvedBookmark.GateItem -> Triple(
            Icons.Default.DirectionsCar,
            scheme.tertiaryContainer,
            scheme.onTertiaryContainer,
        )
        is ResolvedBookmark.ResourceItem -> Triple(
            Icons.Default.Place,
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
        )
        is ResolvedBookmark.EventItem -> Triple(
            Icons.Default.CalendarMonth,
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
        )
        is ResolvedBookmark.Orphan -> Triple(
            Icons.Default.BookmarkBorder,
            scheme.surfaceContainerHighest,
            scheme.onSurfaceVariant,
        )
    }
}
