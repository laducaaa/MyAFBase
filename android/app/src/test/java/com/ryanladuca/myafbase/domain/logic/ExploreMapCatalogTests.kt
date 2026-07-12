package com.ryanladuca.myafbase.domain.logic

import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.Gate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExploreMapCatalogTests {
    private val sampleBase = Base(
        id = "nellis",
        name = "Nellis AFB",
        location = "Nellis AFB, NV",
        latitude = 36.2361,
        longitude = -115.0342,
        wing = "57 WG",
        gates = listOf(
            Gate(
                id = "main",
                name = "Main Gate",
                latitude = 36.24,
                longitude = -115.03,
            ),
        ),
    )

    @Test
    fun directPins_includeBaseAndGate() {
        val pins = ExploreMapCatalog.directPins(sampleBase)
        assertEquals(2, pins.size)
        assertTrue(pins.any { it.kind == ExploreMapPinKind.Base })
        assertTrue(pins.any { it.kind == ExploreMapPinKind.Gate })
    }

    @Test
    fun mapRegion_usesFallbackWhenEmpty() {
        val region = ExploreMapCatalog.mapRegion(emptyList(), sampleBase)
        assertEquals(sampleBase.latitude, region.center.latitude, 0.0001)
        assertEquals(sampleBase.longitude, region.center.longitude, 0.0001)
    }

    @Test
    fun filterPins_matchesTitle() {
        val pins = ExploreMapCatalog.directPins(sampleBase)
        val filtered = ExploreMapCatalog.filterPins(pins, "main")
        assertEquals(1, filtered.size)
        assertEquals("Main Gate", filtered.first().title)
    }
}
