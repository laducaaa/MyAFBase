package com.ryanladuca.myafbase.data.repository

import com.ryanladuca.myafbase.domain.logic.WeatherCondition
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import kotlin.math.roundToInt

class WeatherSnapshotTests {
    @Test
    fun feelsLikeHiddenWhenCloseToActualTemp() {
        val snapshot = WeatherSnapshot(
            tempF = 75.0,
            feelsLikeF = 76.0,
            windMph = 5.0,
            humidity = 40,
            condition = WeatherCondition.Clear,
            isDay = true,
        )
        assertNull(snapshot.feelsLikeDisplayF())
    }

    @Test
    fun feelsLikeShownWhenMeaningfullyDifferent() {
        val snapshot = WeatherSnapshot(
            tempF = 75.0,
            feelsLikeF = 80.0,
            windMph = 5.0,
            humidity = 40,
            condition = WeatherCondition.Clear,
            isDay = true,
        )
        assertEquals(80, snapshot.feelsLikeDisplayF())
    }

    @Test
    fun themeKeyComesFromCondition() {
        val snapshot = WeatherSnapshot(
            tempF = 70.0,
            feelsLikeF = 70.0,
            windMph = 8.0,
            humidity = 55,
            condition = WeatherCondition.Overcast,
            isDay = true,
        )
        assertEquals("Overcast", snapshot.conditionLabel)
        assertEquals("cloudy", snapshot.themeKey)
    }
}
