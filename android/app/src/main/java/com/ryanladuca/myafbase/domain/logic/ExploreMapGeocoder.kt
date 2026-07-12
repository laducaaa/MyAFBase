package com.ryanladuca.myafbase.domain.logic

import android.content.Context
import android.location.Geocoder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Locale

object ExploreMapGeocoder {
    suspend fun resolve(
        context: Context,
        query: String,
        near: ExploreMapCoordinate? = null,
    ): ExploreMapCoordinate? = withContext(Dispatchers.IO) {
        if (!Geocoder.isPresent()) return@withContext null
        val geocoder = Geocoder(context, Locale.US)
        runCatching {
            @Suppress("DEPRECATION")
            val address = geocoder.getFromLocationName(query, 1)?.firstOrNull() ?: return@withContext null
            val coordinate = ExploreMapCoordinate(address.latitude, address.longitude)
            near?.let { anchor ->
                if (!isNearBase(coordinate, anchor)) return@withContext null
            }
            coordinate
        }.getOrNull()
    }

    suspend fun resolveAll(
        context: Context,
        queries: List<ExploreMapAddressQuery>,
        near: ExploreMapCoordinate,
    ): List<ExploreMapPin> = buildList {
        queries.forEach { item ->
            val coordinate = resolve(context, item.query, near) ?: return@forEach
            add(
                ExploreMapPin(
                    id = item.id,
                    title = item.title,
                    subtitle = item.subtitle,
                    coordinate = coordinate,
                    kind = item.kind,
                    isApproximate = true,
                )
            )
        }
    }

    suspend fun searchOnBase(
        context: Context,
        base: com.ryanladuca.myafbase.domain.model.Base,
        query: String,
    ): List<ExploreMapPin> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        val scopedQuery = "$trimmed, ${base.location}"
        val coordinate = resolve(context, scopedQuery) ?: return emptyList()
        return listOf(
            ExploreMapPin(
                id = "search-${trimmed.hashCode()}",
                title = trimmed,
                subtitle = base.location,
                coordinate = coordinate,
                kind = ExploreMapPinKind.Resource,
                isApproximate = true,
            )
        )
    }

    private fun isNearBase(coordinate: ExploreMapCoordinate, anchor: ExploreMapCoordinate): Boolean {
        val latDiff = kotlin.math.abs(coordinate.latitude - anchor.latitude)
        val lonDiff = kotlin.math.abs(coordinate.longitude - anchor.longitude)
        return latDiff < 1.5 && lonDiff < 1.5
    }
}
