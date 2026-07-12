package com.ryanladuca.myafbase.domain.logic

import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.Event
import com.ryanladuca.myafbase.domain.model.Gate
import com.ryanladuca.myafbase.domain.model.Resource
import kotlin.math.ln

enum class ExploreMapPinKind {
    Base,
    Gate,
    Resource,
    Event,
}

data class ExploreMapCoordinate(
    val latitude: Double,
    val longitude: Double,
)

data class ExploreMapPin(
    val id: String,
    val title: String,
    val subtitle: String?,
    val coordinate: ExploreMapCoordinate,
    val kind: ExploreMapPinKind,
    val isApproximate: Boolean = false,
)

data class ExploreMapAddressQuery(
    val id: String,
    val query: String,
    val title: String,
    val subtitle: String?,
    val kind: ExploreMapPinKind,
)

data class ExploreMapRegion(
    val center: ExploreMapCoordinate,
    val spanDelta: Double,
)

object ExploreMapCatalog {
    fun directPins(
        base: Base,
        gates: List<Gate> = base.gates,
        resources: List<Resource> = base.resources,
        events: List<Event> = base.events,
        includeBaseCenter: Boolean = true,
    ): List<ExploreMapPin> = buildList {
        if (includeBaseCenter) {
            add(
                ExploreMapPin(
                    id = "base-${base.id}",
                    title = base.name,
                    subtitle = base.location,
                    coordinate = ExploreMapCoordinate(base.latitude, base.longitude),
                    kind = ExploreMapPinKind.Base,
                )
            )
        }
        gates.forEach { gate ->
            val coordinate = gate.mapCoordinate ?: return@forEach
            add(
                ExploreMapPin(
                    id = "gate-${gate.id}",
                    title = gate.name,
                    subtitle = gate.displayAddress,
                    coordinate = coordinate,
                    kind = ExploreMapPinKind.Gate,
                )
            )
        }
        resources.forEach { resource ->
            val coordinate = resource.mapCoordinate ?: return@forEach
            add(
                ExploreMapPin(
                    id = "resource-${resource.id}",
                    title = resource.name,
                    subtitle = resource.displayAddress,
                    coordinate = coordinate,
                    kind = ExploreMapPinKind.Resource,
                )
            )
        }
        events.forEach { event ->
            val coordinate = event.mapCoordinate ?: return@forEach
            add(
                ExploreMapPin(
                    id = "event-${event.id}",
                    title = event.title,
                    subtitle = event.displayAddress,
                    coordinate = coordinate,
                    kind = ExploreMapPinKind.Event,
                )
            )
        }
    }

    fun addressQueries(
        base: Base,
        gates: List<Gate> = base.gates,
        resources: List<Resource> = base.resources,
        events: List<Event> = base.events,
        limit: Int = 10,
    ): List<ExploreMapAddressQuery> = buildList {
        gates.filter { it.mapCoordinate == null }.forEach { gate ->
            val query = geocodeQuery(gate.displayAddress, base) ?: return@forEach
            add(
                ExploreMapAddressQuery(
                    id = "gate-${gate.id}",
                    query = query,
                    title = gate.name,
                    subtitle = gate.displayAddress,
                    kind = ExploreMapPinKind.Gate,
                )
            )
        }
        resources.filter { it.mapCoordinate == null }.forEach { resource ->
            val query = geocodeQuery(resource.displayAddress, base) ?: return@forEach
            add(
                ExploreMapAddressQuery(
                    id = "resource-${resource.id}",
                    query = query,
                    title = resource.name,
                    subtitle = resource.displayAddress,
                    kind = ExploreMapPinKind.Resource,
                )
            )
        }
        events.filter { it.mapCoordinate == null }.forEach { event ->
            val query = geocodeQuery(event.displayAddress, base) ?: return@forEach
            add(
                ExploreMapAddressQuery(
                    id = "event-${event.id}",
                    query = query,
                    title = event.title,
                    subtitle = event.displayAddress,
                    kind = ExploreMapPinKind.Event,
                )
            )
        }
    }.take(limit)

    fun mapRegion(pins: List<ExploreMapPin>, fallback: Base): ExploreMapRegion {
        if (pins.isEmpty()) {
            return ExploreMapRegion(
                center = ExploreMapCoordinate(fallback.latitude, fallback.longitude),
                spanDelta = 0.08,
            )
        }
        val latitudes = pins.map { it.coordinate.latitude }
        val longitudes = pins.map { it.coordinate.longitude }
        val minLat = latitudes.min()
        val maxLat = latitudes.max()
        val minLon = longitudes.min()
        val maxLon = longitudes.max()
        val center = ExploreMapCoordinate(
            latitude = (minLat + maxLat) / 2,
            longitude = (minLon + maxLon) / 2,
        )
        val latDelta = maxOf((maxLat - minLat) * 1.35, 0.02)
        val lonDelta = maxOf((maxLon - minLon) * 1.35, 0.02)
        val spanDelta = maxOf(latDelta, lonDelta, 0.04)
        return ExploreMapRegion(center = center, spanDelta = spanDelta)
    }

    fun spanDeltaToZoom(spanDelta: Double): Float {
        val zoom = (ln(360.0 / spanDelta) / ln(2.0)).toFloat()
        return zoom.coerceIn(4f, 16f)
    }

    fun filterPins(pins: List<ExploreMapPin>, query: String): List<ExploreMapPin> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return pins
        return pins.filter { pin ->
            pin.title.contains(trimmed, ignoreCase = true) ||
                pin.subtitle?.contains(trimmed, ignoreCase = true) == true
        }
    }

    private fun geocodeQuery(address: String?, base: Base): String? {
        if (address.isNullOrBlank()) return null
        return if (address.contains(base.location, ignoreCase = true)) {
            address
        } else {
            "$address, ${base.location}"
        }
    }
}

private val Gate.mapCoordinate: ExploreMapCoordinate?
    get() {
        val lat = latitude ?: return null
        val lon = longitude ?: return null
        return ExploreMapCoordinate(lat, lon)
    }

private val Resource.mapCoordinate: ExploreMapCoordinate?
    get() {
        val lat = latitude ?: return null
        val lon = longitude ?: return null
        return ExploreMapCoordinate(lat, lon)
    }

private val Event.mapCoordinate: ExploreMapCoordinate?
    get() = null

private val Gate.displayAddress: String?
    get() = address?.takeIf { it.isNotBlank() }
