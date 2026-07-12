package com.ryanladuca.myafbase.ui.explore

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Directions
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.BookmarkEntity
import com.ryanladuca.myafbase.domain.logic.HoursParser
import com.ryanladuca.myafbase.domain.model.BookmarkTargetType
import com.ryanladuca.myafbase.domain.model.Event
import com.ryanladuca.myafbase.domain.model.Gate
import com.ryanladuca.myafbase.domain.model.Resource
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.components.AppSegmentedControl
import com.ryanladuca.myafbase.ui.components.EmptyBasePrompt
import com.ryanladuca.myafbase.ui.components.M3FlatScreenBackground
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppChipDefaults
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch

private enum class ExploreSegment { Resources, Events }

private sealed class ExploreListEntry(val key: String) {
    data class GateItem(val gate: Gate) : ExploreListEntry("g-${gate.id}")
    data class ResourceItem(val resource: Resource) : ExploreListEntry("r-${resource.id}")
    data class EventItem(val event: Event) : ExploreListEntry("e-${event.id}")
}

@Composable
fun ExploreScreen(
    onPickBase: () -> Unit,
    contentPadding: PaddingValues,
) {
    val appState = LocalAppState.current
    val container = LocalAppContainer.current
    val baseState by appState.currentBase.collectAsState()
    var segment by remember { mutableStateOf(ExploreSegment.Resources) }
    var query by remember { mutableStateOf("") }
    var openNowOnly by remember { mutableStateOf(false) }
    var category by remember { mutableStateOf("all") }
    var showMap by remember { mutableStateOf(false) }
    var hasOpenedMap by remember { mutableStateOf(false) }
    var scrollTargetKey by remember { mutableStateOf<String?>(null) }
    var detailTarget by remember { mutableStateOf<ExploreDetailTarget?>(null) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val listState = rememberLazyListState()
    val pendingExplore by appState.pendingExploreDestination.collectAsState()

    LaunchedEffect(pendingExplore) {
        val dest = appState.consumeExploreDestination() ?: return@LaunchedEffect
        segment = if (dest.segment == "events") ExploreSegment.Events else ExploreSegment.Resources
        category = dest.category ?: "all"
        scrollTargetKey = dest.targetType?.let { type ->
            dest.targetId?.let { id ->
                when (type) {
                    BookmarkTargetType.GATE -> "g-$id"
                    BookmarkTargetType.RESOURCE -> "r-$id"
                    BookmarkTargetType.EVENT -> "e-$id"
                }
            }
        }
        showMap = false
    }

    val base = baseState
    if (base == null) {
        EmptyBasePrompt(onPickBase = onPickBase, contentPadding = contentPadding)
        return
    }

    LaunchedEffect(showMap) {
        if (showMap) hasOpenedMap = true
    }

    val bookmarks by container.database.bookmarkDao().observeForBase(base.id)
        .collectAsState(initial = emptyList())
    val bookmarkedIds = bookmarks.map { it.id }.toSet()

    fun bookmarkId(type: BookmarkTargetType, targetId: String) = "${base.id}:${type.raw}:$targetId"

    fun toggleBookmark(type: BookmarkTargetType, targetId: String, title: String, subtitle: String?) {
        scope.launch {
            val id = bookmarkId(type, targetId)
            if (bookmarkedIds.contains(id)) {
                container.database.bookmarkDao().delete(id)
            } else {
                container.database.bookmarkDao().upsert(
                    BookmarkEntity(id, base.id, type.raw, targetId, title, subtitle),
                )
            }
            appState.syncWidgets()
        }
    }

    val openNowCount = base.gates.count { HoursParser.isOpenNow(it.hours) == true } +
        base.resources.count { HoursParser.isOpenNow(it.displayHours) == true }

    val gates = base.gates.filter {
        (category == "all" || category == "gates") &&
            (query.isBlank() || it.name.contains(query, true) || it.hours.contains(query, true)) &&
            (!openNowOnly || HoursParser.isOpenNow(it.hours) == true)
    }
    val resources = base.resources.filter {
        category != "gates" &&
            (category == "all" || it.category.equals(category, true)) &&
            (query.isBlank() || it.name.contains(query, true) || (it.description?.contains(query, true) == true)) &&
            (!openNowOnly || HoursParser.isOpenNow(it.displayHours) == true)
    }
    val events = base.events.filter {
        (category == "all" || it.category.equals(category, true)) &&
            (query.isBlank() || it.title.contains(query, true) || it.description.contains(query, true))
    }

    val listEntries = remember(segment, gates, resources, events, category) {
        buildList {
            if (segment == ExploreSegment.Resources) {
                if (category == "all" || category == "gates") {
                    gates.forEach { add(ExploreListEntry.GateItem(it)) }
                }
                if (category != "gates") {
                    resources.forEach { add(ExploreListEntry.ResourceItem(it)) }
                }
            } else {
                events.forEach { add(ExploreListEntry.EventItem(it)) }
            }
        }
    }

    LaunchedEffect(scrollTargetKey, listEntries, showMap) {
        val targetKey = scrollTargetKey ?: return@LaunchedEffect
        if (showMap) return@LaunchedEffect
        val index = listEntries.indexOfFirst { it.key == targetKey }
        if (index >= 0) {
            listState.animateScrollToItem(index)
        }
        scrollTargetKey = null
    }

    val cats = if (segment == ExploreSegment.Resources) exploreResourceCategories() else exploreEventCategories()

    M3FlatScreenBackground {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding)
                .padding(horizontal = AppTokens.screenPadding),
        ) {
            ExploreFilterChrome(
                showMap = showMap,
                onShowMapChange = { showMap = it },
                query = query,
                onQueryChange = { query = it },
                segment = segment,
                onSegmentChange = { next ->
                    segment = next
                    category = "all"
                    openNowOnly = false
                },
                openNowOnly = openNowOnly,
                onOpenNowOnlyChange = { openNowOnly = it },
                openNowCount = openNowCount,
                categories = cats,
                selectedCategory = category,
                onCategorySelected = { category = it },
            )

            Box(modifier = Modifier.weight(1f)) {
                if (showMap) {
                    if (hasOpenedMap) {
                        ExploreMapScreen(
                            base = base,
                            gates = gates,
                            resources = resources,
                            events = events,
                            searchQuery = query,
                            isActive = true,
                            modifier = Modifier.fillMaxSize(),
                        )
                    }
                } else {
                    ExploreListContent(
                        listState = listState,
                        entries = listEntries,
                        openNowOnly = openNowOnly,
                        query = query,
                        category = category,
                        segment = segment,
                        bookmarkedIds = bookmarkedIds,
                        baseId = base.id,
                        onToggleBookmark = ::toggleBookmark,
                        onOpenMaps = { lat, lon, label ->
                            openMaps(context, lat, lon, label)
                        },
                        onCall = { phone ->
                            context.startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone")))
                        },
                        onOpenDetail = { detailTarget = it },
                    )
                }
            }
        }
    }

    when (val target = detailTarget) {
        is ExploreDetailTarget.GateItem -> {
            val gate = target.gate
            LocationDetailSheet(
                title = gate.name,
                hours = gate.hours,
                address = gate.address,
                phone = null,
                url = null,
                description = gate.notes,
                gateStatus = gate.status,
                traffic = gate.traffic,
                onOpenMaps = {
                    openMaps(context, gate.latitude, gate.longitude, gate.address ?: gate.name)
                },
                onDismiss = { detailTarget = null },
            )
        }
        is ExploreDetailTarget.ResourceItem -> {
            val resource = target.resource
            LocationDetailSheet(
                title = resource.name,
                hours = resource.displayHours,
                address = resource.displayAddress,
                phone = resource.displayPhone,
                url = resource.displayURL,
                description = resource.description,
                onOpenMaps = {
                    openMaps(
                        context,
                        resource.latitude,
                        resource.longitude,
                        resource.displayAddress ?: resource.name,
                    )
                },
                onDismiss = { detailTarget = null },
            )
        }
        is ExploreDetailTarget.EventItem -> {
            EventDetailSheet(
                event = target.event,
                onOpenMaps = target.event.displayAddress?.let { address ->
                    { openMaps(context, null, null, address) }
                },
                onDismiss = { detailTarget = null },
            )
        }
        null -> Unit
    }
}

@Composable
private fun ExploreFilterChrome(
    showMap: Boolean,
    onShowMapChange: (Boolean) -> Unit,
    query: String,
    onQueryChange: (String) -> Unit,
    segment: ExploreSegment,
    onSegmentChange: (ExploreSegment) -> Unit,
    openNowOnly: Boolean,
    onOpenNowOnlyChange: (Boolean) -> Unit,
    openNowCount: Int,
    categories: List<ExploreCategory>,
    selectedCategory: String,
    onCategorySelected: (String) -> Unit,
) {
    val scheme = MaterialTheme.colorScheme

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 12.dp),
        shape = MaterialTheme.shapes.extraLarge,
        color = scheme.surfaceContainerHigh,
        tonalElevation = 1.dp,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            AppSegmentedControl(
                options = listOf("List", "Map"),
                selectedIndex = if (showMap) 1 else 0,
                onSelected = { onShowMapChange(it == 1) },
                equalWidth = true,
            )

            OutlinedTextField(
                value = query,
                onValueChange = onQueryChange,
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                placeholder = {
                    Text(
                        if (segment == ExploreSegment.Events) {
                            "Search events"
                        } else {
                            "Search gates and resources"
                        },
                    )
                },
                singleLine = true,
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )

            AppSegmentedControl(
                options = listOf("Resources", "Events"),
                selectedIndex = if (segment == ExploreSegment.Resources) 0 else 1,
                onSelected = {
                    onSegmentChange(if (it == 0) ExploreSegment.Resources else ExploreSegment.Events)
                },
                equalWidth = true,
            )

            if (segment == ExploreSegment.Resources) {
                FilterChip(
                    selected = openNowOnly,
                    onClick = { onOpenNowOnlyChange(!openNowOnly) },
                    label = { Text("Open now ($openNowCount)") },
                    colors = AppChipDefaults.filterChip(selected = openNowOnly),
                )
            }

            ExploreCategoryBar(
                categories = categories,
                selectedId = selectedCategory,
                onSelected = onCategorySelected,
            )
        }
    }
}

@Composable
private fun ExploreListContent(
    listState: LazyListState,
    entries: List<ExploreListEntry>,
    openNowOnly: Boolean,
    query: String,
    category: String,
    segment: ExploreSegment,
    bookmarkedIds: Set<String>,
    baseId: String,
    onToggleBookmark: (BookmarkTargetType, String, String, String?) -> Unit,
    onOpenMaps: (Double?, Double?, String) -> Unit,
    onCall: (String) -> Unit,
    onOpenDetail: (ExploreDetailTarget) -> Unit,
) {
    val scheme = MaterialTheme.colorScheme

    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(0.dp),
        contentPadding = PaddingValues(bottom = 24.dp),
    ) {
        if (entries.isEmpty()) {
            item {
                ExploreEmptyState(
                    openNowOnly = openNowOnly,
                    query = query,
                    category = category,
                    segment = segment,
                )
            }
        } else {
            itemsIndexed(entries, key = { _, entry -> entry.key }) { index, entry ->
                val shape = groupedItemShape(index = index, count = entries.size)
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = shape,
                    color = scheme.surfaceContainerHigh,
                    tonalElevation = if (index == 0) 1.dp else 0.dp,
                ) {
                    when (entry) {
                        is ExploreListEntry.GateItem -> ExploreGateListItem(
                            gate = entry.gate,
                            bookmarked = bookmarkedIds.contains("${baseId}:${BookmarkTargetType.GATE.raw}:${entry.gate.id}"),
                            onToggleBookmark = {
                                onToggleBookmark(BookmarkTargetType.GATE, entry.gate.id, entry.gate.name, entry.gate.hours)
                            },
                            onOpenMaps = {
                                onOpenMaps(entry.gate.latitude, entry.gate.longitude, entry.gate.address ?: entry.gate.name)
                            },
                            onOpenDetail = { onOpenDetail(ExploreDetailTarget.GateItem(entry.gate)) },
                        )
                        is ExploreListEntry.ResourceItem -> ExploreResourceListItem(
                            resource = entry.resource,
                            bookmarked = bookmarkedIds.contains("${baseId}:${BookmarkTargetType.RESOURCE.raw}:${entry.resource.id}"),
                            onToggleBookmark = {
                                onToggleBookmark(
                                    BookmarkTargetType.RESOURCE,
                                    entry.resource.id,
                                    entry.resource.name,
                                    entry.resource.displayHours,
                                )
                            },
                            onOpenMaps = {
                                onOpenMaps(
                                    entry.resource.latitude,
                                    entry.resource.longitude,
                                    entry.resource.displayAddress ?: entry.resource.name,
                                )
                            },
                            onCall = entry.resource.displayPhone?.let { phone -> { onCall(phone) } },
                            onOpenDetail = { onOpenDetail(ExploreDetailTarget.ResourceItem(entry.resource)) },
                        )
                        is ExploreListEntry.EventItem -> ExploreEventListItem(
                            event = entry.event,
                            bookmarked = bookmarkedIds.contains("${baseId}:${BookmarkTargetType.EVENT.raw}:${entry.event.id}"),
                            onToggleBookmark = {
                                onToggleBookmark(
                                    BookmarkTargetType.EVENT,
                                    entry.event.id,
                                    entry.event.title,
                                    entry.event.displayAddress,
                                )
                            },
                            onOpenDetail = { onOpenDetail(ExploreDetailTarget.EventItem(entry.event)) },
                        )
                    }
                }
                if (index < entries.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        color = scheme.outlineVariant,
                    )
                }
            }
            item { SpacerBetweenResultsAndDisclaimer() }
        }

        item {
            Text(
                "Hours and contacts may be outdated. Verify with official installation sources.",
                style = MaterialTheme.typography.bodySmall,
                color = scheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp),
            )
        }
    }
}

@Composable
private fun SpacerBetweenResultsAndDisclaimer() {
    Spacer(modifier = Modifier.padding(top = 12.dp))
}

@Composable
private fun ExploreEmptyState(
    openNowOnly: Boolean,
    query: String,
    category: String,
    segment: ExploreSegment,
) {
    val scheme = MaterialTheme.colorScheme
    val (title, body) = when {
        openNowOnly -> "Nothing open right now" to "Try turning off Open now or pick another category."
        query.isNotBlank() -> "No matches" to "Try a different search term or browse another category."
        category != "all" -> "No items in this category" to "Pick All or try another filter."
        segment == ExploreSegment.Events -> "No events listed" to "Check back later or try another category."
        else -> "No resources found" to "Try another category or search term."
    }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = scheme.surfaceContainerHigh,
        tonalElevation = 1.dp,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Surface(
                shape = MaterialTheme.shapes.large,
                color = scheme.primaryContainer,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    imageVector = Icons.Default.Place,
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
            )
            Text(
                text = body,
                style = MaterialTheme.typography.bodyMedium,
                color = scheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun ExploreGateListItem(
    gate: Gate,
    bookmarked: Boolean,
    onToggleBookmark: () -> Unit,
    onOpenMaps: () -> Unit,
    onOpenDetail: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val open = HoursParser.isOpenNow(gate.hours)
    val statusLine = buildList {
        add(gate.status.replaceFirstChar { it.uppercase() })
        if (open != null) add(if (open) "Open now" else "Closed")
    }.joinToString(" · ")

    ExploreListItem(
        title = gate.name,
        subtitle = gate.hours,
        detail = gate.notes?.takeIf { it.isNotBlank() },
        meta = statusLine,
        icon = Icons.Default.DirectionsCar,
        containerColor = scheme.tertiaryContainer,
        contentColor = scheme.onTertiaryContainer,
        bookmarked = bookmarked,
        onToggleBookmark = onToggleBookmark,
        onDirections = onOpenMaps,
        onClick = onOpenDetail,
    )
}

@Composable
private fun ExploreResourceListItem(
    resource: Resource,
    bookmarked: Boolean,
    onToggleBookmark: () -> Unit,
    onOpenMaps: () -> Unit,
    onCall: (() -> Unit)?,
    onOpenDetail: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val open = HoursParser.isOpenNow(resource.displayHours)
    val subtitle = listOfNotNull(
        resource.category.replaceFirstChar { it.uppercase() },
        resource.displayHours,
    ).joinToString(" · ")
    val meta = open?.let { if (it) "Open now" else "Closed" }

    ExploreListItem(
        title = resource.name,
        subtitle = subtitle,
        detail = resource.description?.takeIf { it.isNotBlank() },
        meta = meta,
        icon = exploreCategoryIcon(resource.category, isEvents = false),
        containerColor = scheme.primaryContainer,
        contentColor = scheme.onPrimaryContainer,
        bookmarked = bookmarked,
        onToggleBookmark = onToggleBookmark,
        onDirections = onOpenMaps,
        onCall = onCall,
        onClick = onOpenDetail,
    )
}

@Composable
private fun ExploreEventListItem(
    event: Event,
    bookmarked: Boolean,
    onToggleBookmark: () -> Unit,
    onOpenDetail: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val subtitle = listOfNotNull(
        event.category?.replaceFirstChar { it.uppercase() },
        event.date,
        event.displayAddress?.takeIf { it.isNotBlank() },
    ).joinToString(" · ")

    ExploreListItem(
        title = event.title,
        subtitle = subtitle,
        detail = event.description.takeIf { it.isNotBlank() },
        meta = null,
        icon = exploreCategoryIcon(event.category.orEmpty(), isEvents = true),
        containerColor = scheme.secondaryContainer,
        contentColor = scheme.onSecondaryContainer,
        bookmarked = bookmarked,
        onToggleBookmark = onToggleBookmark,
        onClick = onOpenDetail,
    )
}

@Composable
private fun ExploreListItem(
    title: String,
    subtitle: String,
    detail: String?,
    meta: String?,
    icon: ImageVector,
    containerColor: Color,
    contentColor: Color,
    bookmarked: Boolean,
    onToggleBookmark: () -> Unit,
    onDirections: (() -> Unit)? = null,
    onCall: (() -> Unit)? = null,
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
        headlineContent = {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        },
        supportingContent = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = scheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                meta?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.labelMedium,
                        color = scheme.primary,
                        fontWeight = FontWeight.Medium,
                    )
                }
                detail?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodySmall,
                        color = scheme.onSurfaceVariant,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                if (onCall != null || onDirections != null) {
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        onCall?.let { call ->
                            TextButton(onClick = call, colors = AppButtonDefaults.text()) {
                                Icon(Icons.Default.Phone, contentDescription = null, modifier = Modifier.size(16.dp))
                                Text("Call", modifier = Modifier.padding(start = 4.dp))
                            }
                        }
                        onDirections?.let { directions ->
                            TextButton(onClick = directions, colors = AppButtonDefaults.text()) {
                                Icon(Icons.Default.Directions, contentDescription = null, modifier = Modifier.size(16.dp))
                                Text("Directions", modifier = Modifier.padding(start = 4.dp))
                            }
                        }
                    }
                }
            }
        },
        trailingContent = {
            IconButton(onClick = onToggleBookmark) {
                Icon(
                    imageVector = if (bookmarked) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                    contentDescription = if (bookmarked) "Remove bookmark" else "Bookmark",
                    tint = if (bookmarked) scheme.primary else scheme.onSurfaceVariant,
                )
            }
        },
    )
}

private fun groupedItemShape(index: Int, count: Int): Shape {
    val radius = 20.dp
    return when {
        count == 1 -> RoundedCornerShape(radius)
        index == 0 -> RoundedCornerShape(topStart = radius, topEnd = radius, bottomEnd = 0.dp, bottomStart = 0.dp)
        index == count - 1 -> RoundedCornerShape(bottomStart = radius, bottomEnd = radius, topStart = 0.dp, topEnd = 0.dp)
        else -> RoundedCornerShape(0.dp)
    }
}

fun openMaps(context: android.content.Context, lat: Double?, lon: Double?, label: String) {
    val uri = if (lat != null && lon != null) {
        Uri.parse("geo:$lat,$lon?q=$lat,$lon(${Uri.encode(label)})")
    } else {
        Uri.parse("geo:0,0?q=${Uri.encode(label)}")
    }
    context.startActivity(Intent(Intent.ACTION_VIEW, uri))
}
