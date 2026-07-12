package com.ryanladuca.myafbase.ui.theme

import org.junit.Assert.assertEquals
import org.junit.Test

class WeatherHeroThemeTests {
    @Test
    fun clearUsesSunnyPalette() {
        val palette = WeatherHeroTheme.palette("clear")
        assertEquals(3, palette.colors.size)
        assertEquals(0.18f, palette.symbolOpacity, 0.001f)
    }

    @Test
    fun rainUsesRainPalette() {
        val palette = WeatherHeroTheme.palette("rain")
        assertEquals(3, palette.colors.size)
        assertEquals(0.15f, palette.symbolOpacity, 0.001f)
    }

    @Test
    fun thunderstormUsesStormPalette() {
        val palette = WeatherHeroTheme.palette("thunderstorm")
        assertEquals(3, palette.colors.size)
        assertEquals(0.16f, palette.symbolOpacity, 0.001f)
    }

    @Test
    fun overcastThemeKeyUsesCloudyPalette() {
        val palette = WeatherHeroTheme.palette("cloudy")
        assertEquals(3, palette.colors.size)
        assertEquals(0.14f, palette.symbolOpacity, 0.001f)
    }

    @Test
    fun unknownFallsBackToNeutralPalette() {
        val palette = WeatherHeroTheme.palette("unavailable")
        assertEquals(2, palette.colors.size)
        assertEquals(0.10f, palette.symbolOpacity, 0.001f)
    }
}
