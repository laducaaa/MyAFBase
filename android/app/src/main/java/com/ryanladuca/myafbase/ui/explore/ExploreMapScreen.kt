package com.ryanladuca.myafbase.ui.explore

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.ZoomOutMap
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import com.ryanladuca.myafbase.domain.logic.ExploreMapCatalog
import com.ryanladuca.myafbase.domain.logic.ExploreMapGeocoder
import com.ryanladuca.myafbase.domain.logic.ExploreMapPin
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.Event
import com.ryanladuca.myafbase.domain.model.Gate
import com.ryanladuca.myafbase.domain.model.Resource
import com.ryanladuca.myafbase.ui.theme.AppTokens

@Composable
fun ExploreMapScreen(
    base: Base,
    gates: List<Gate>,
    resources: List<Resource>,
    events: List<Event>,
    searchQuery: String = "",
    isActive: Boolean = true,
    modifier: Modifier = Modifier,
) {
    ExploreMapContent(
        base = base,
        gates = gates,
        resources = resources,
        events = events,
        searchQuery = searchQuery,
        isActive = isActive,
        modifier = modifier,
    )
}

@Composable
private fun ExploreMapContent(
    base: Base,
    gates: List<Gate>,
    resources: List<Resource>,
    events: List<Event>,
    searchQuery: String,
    isActive: Boolean,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val scheme = MaterialTheme.colorScheme
    val directPins = remember(base.id, gates, resources, events) {
        ExploreMapCatalog.directPins(
            base = base,
            gates = gates,
            resources = resources,
            events = events,
        )
    }
    var geocodedPins by remember(base.id, gates, resources, events) {
        mutableStateOf<List<ExploreMapPin>>(emptyList())
    }
    var searchPins by remember { mutableStateOf<List<ExploreMapPin>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }
    var locationGranted by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED,
        )
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        locationGranted = granted
    }

    LaunchedEffect(base.id, isActive) {
        if (!isActive) return@LaunchedEffect
        if (!locationGranted) {
            permissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    LaunchedEffect(base.id, gates, resources, events) {
        val anchor = ExploreMapCatalog.directPins(base, includeBaseCenter = true)
            .firstOrNull()?.coordinate
            ?: return@LaunchedEffect
        val queries = ExploreMapCatalog.addressQueries(
            base = base,
            gates = gates,
            resources = resources,
            events = events,
        )
        geocodedPins = ExploreMapGeocoder.resolveAll(
            context = context,
            queries = queries,
            near = anchor,
        )
    }

    LaunchedEffect(base.id, searchQuery, isActive) {
        if (!isActive) return@LaunchedEffect
        val trimmed = searchQuery.trim()
        if (trimmed.isEmpty()) {
            searchPins = emptyList()
            isSearching = false
            return@LaunchedEffect
        }
        isSearching = true
        searchPins = ExploreMapGeocoder.searchOnBase(context, base, trimmed)
        isSearching = false
    }

    val filteredDirect = remember(directPins, searchQuery) {
        ExploreMapCatalog.filterPins(directPins, searchQuery)
    }
    val allPins = remember(filteredDirect, geocodedPins, searchPins, searchQuery) {
        val trimmed = searchQuery.trim()
        buildList {
            addAll(filteredDirect)
            if (trimmed.isEmpty()) {
                addAll(geocodedPins)
            }
            addAll(searchPins)
        }.distinctBy { it.id }
    }

    val region = remember(allPins, base.id) {
        ExploreMapCatalog.mapRegion(allPins.ifEmpty { ExploreMapCatalog.directPins(base) }, base)
    }
    val center = LatLng(region.center.latitude, region.center.longitude)
    val zoom = ExploreMapCatalog.spanDeltaToZoom(region.spanDelta)
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(center, zoom)
    }

    LaunchedEffect(region, isActive, searchQuery) {
        if (!isActive) return@LaunchedEffect
        cameraPositionState.position = CameraPosition.fromLatLngZoom(center, zoom)
    }

    Box(modifier = modifier.fillMaxSize()) {
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = MapProperties(isMyLocationEnabled = locationGranted),
            uiSettings = MapUiSettings(
                compassEnabled = true,
                myLocationButtonEnabled = false,
                zoomControlsEnabled = false,
            ),
        ) {
            allPins.forEach { pin ->
                Marker(
                    state = MarkerState(
                        position = LatLng(pin.coordinate.latitude, pin.coordinate.longitude),
                    ),
                    title = pin.title,
                    snippet = pin.subtitle,
                )
            }
        }

        if (isActive) {
            MapChrome(
                isSearching = isSearching,
                resultCount = allPins.size,
                hasSearch = searchQuery.isNotBlank(),
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(AppTokens.screenPadding),
            )
        }

        FloatingActionButton(
            onClick = {
                cameraPositionState.position = CameraPosition.fromLatLngZoom(center, zoom)
            },
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(AppTokens.screenPadding),
            containerColor = scheme.primaryContainer,
            contentColor = scheme.onPrimaryContainer,
            shape = MaterialTheme.shapes.large,
        ) {
            Icon(Icons.Default.ZoomOutMap, contentDescription = "Reset map region")
        }

        if (!locationGranted) {
            FloatingActionButton(
                onClick = {
                    permissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
                },
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(AppTokens.screenPadding),
                containerColor = scheme.secondaryContainer,
                contentColor = scheme.onSecondaryContainer,
                shape = MaterialTheme.shapes.large,
            ) {
                Icon(Icons.Default.MyLocation, contentDescription = "Enable location")
            }
        }

        Surface(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            shape = MaterialTheme.shapes.large,
            color = scheme.surfaceContainerHigh.copy(alpha = 0.94f),
            tonalElevation = 2.dp,
        ) {
            Text(
                buildString {
                    append("${allPins.size} location")
                    if (allPins.size != 1) append("s")
                    if (searchQuery.isNotBlank()) append(" matching \"$searchQuery\"")
                    append(" on map")
                },
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                style = MaterialTheme.typography.labelMedium,
                color = scheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun MapChrome(
    isSearching: Boolean,
    resultCount: Int,
    hasSearch: Boolean,
    modifier: Modifier = Modifier,
) {
    if (!isSearching && !hasSearch) return
    Surface(
        modifier = modifier,
        shape = MaterialTheme.shapes.large,
        color = MaterialTheme.colorScheme.surfaceContainerHigh.copy(alpha = 0.94f),
        tonalElevation = 2.dp,
    ) {
        Box(modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
            when {
                isSearching -> {
                    CircularProgressIndicator(
                        modifier = Modifier.padding(4.dp),
                        strokeWidth = 2.dp,
                    )
                }
                hasSearch -> {
                    Text(
                        "$resultCount results",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}
