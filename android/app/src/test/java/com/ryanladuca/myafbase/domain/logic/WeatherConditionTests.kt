package com.ryanladuca.myafbase.domain.logic

import org.junit.Assert.assertEquals
import org.junit.Test

class WeatherConditionTests {
    @Test
    fun mapsWmoCodes() {
        assertEquals("Clear", WeatherCondition.fromWmoCode(0).displayName)
        assertEquals("Partly Cloudy", WeatherCondition.fromWmoCode(2).displayName)
        assertEquals("Overcast", WeatherCondition.fromWmoCode(3).displayName)
        assertEquals("Rain", WeatherCondition.fromWmoCode(61).displayName)
        assertEquals("Thunderstorm", WeatherCondition.fromWmoCode(95).displayName)
    }

    @Test
    fun themeKey_groupsOvercastAsCloudy() {
        assertEquals("cloudy", WeatherCondition.Overcast.themeKey)
        assertEquals("rain", WeatherCondition.RainShowers.themeKey)
        assertEquals("clear", WeatherCondition.MainlyClear.themeKey)
    }

    @Test
    fun reconcilesFalseThunderstormFromOpenMeteo() {
        val condition = WeatherCondition.resolved(
            wmoCode = 95,
            cloudCoverPercent = 18,
            precipitationInches = 0.0,
        )
        assertEquals("Mainly Clear", condition.displayName)
        assertEquals("clear", condition.themeKey)
    }

    @Test
    fun keepsThunderstormWhenPrecipitationPresent() {
        val condition = WeatherCondition.resolved(
            wmoCode = 95,
            cloudCoverPercent = 80,
            precipitationInches = 0.2,
        )
        assertEquals("Thunderstorm", condition.displayName)
        assertEquals("thunderstorm", condition.themeKey)
    }
}
