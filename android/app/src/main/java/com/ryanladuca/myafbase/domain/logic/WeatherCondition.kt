package com.ryanladuca.myafbase.domain.logic

enum class WeatherCondition {
    Clear,
    MainlyClear,
    PartlyCloudy,
    Overcast,
    Fog,
    Drizzle,
    FreezingDrizzle,
    Rain,
    FreezingRain,
    Snow,
    RainShowers,
    SnowShowers,
    Thunderstorm,
    Unknown;

    val displayName: String
        get() = when (this) {
            Clear -> "Clear"
            MainlyClear -> "Mainly Clear"
            PartlyCloudy -> "Partly Cloudy"
            Overcast -> "Overcast"
            Fog -> "Fog"
            Drizzle -> "Drizzle"
            FreezingDrizzle -> "Freezing Drizzle"
            Rain -> "Rain"
            FreezingRain -> "Freezing Rain"
            Snow -> "Snow"
            RainShowers -> "Rain Showers"
            SnowShowers -> "Snow Showers"
            Thunderstorm -> "Thunderstorm"
            Unknown -> "Unknown"
        }

    /** Groups conditions for hero background styling (matches iOS `themeKey`). */
    val themeKey: String
        get() = when (this) {
            Clear, MainlyClear -> "clear"
            PartlyCloudy -> "partly cloudy"
            Overcast -> "cloudy"
            Fog -> "fog"
            Drizzle, FreezingDrizzle, Rain, FreezingRain, RainShowers -> "rain"
            Snow, SnowShowers -> "snow"
            Thunderstorm -> "thunderstorm"
            Unknown -> "unknown"
        }

    companion object {
        fun fromWmoCode(code: Int): WeatherCondition = when (code) {
            0 -> Clear
            1 -> MainlyClear
            2 -> PartlyCloudy
            3 -> Overcast
            45, 48 -> Fog
            51, 53, 55 -> Drizzle
            56, 57 -> FreezingDrizzle
            61, 63, 65 -> Rain
            66, 67 -> FreezingRain
            71, 73, 75, 77 -> Snow
            80, 81, 82 -> RainShowers
            85, 86 -> SnowShowers
            95, 96, 99 -> Thunderstorm
            else -> Unknown
        }

        fun resolved(
            wmoCode: Int,
            cloudCoverPercent: Int?,
            precipitationInches: Double?,
        ): WeatherCondition {
            val raw = fromWmoCode(wmoCode)
            val precip = maxOf(precipitationInches ?: 0.0, 0.0)
            val hasSignificantPrecip = precip >= 0.01

            if (!isPrecipitationRelated(wmoCode) || hasSignificantPrecip) {
                return raw
            }

            cloudCoverPercent?.let { return fromCloudCover(it) }

            if (wmoCode >= 95) {
                return PartlyCloudy
            }

            return raw
        }

        private fun isPrecipitationRelated(wmoCode: Int): Boolean = when (wmoCode) {
            in 51..67, in 71..77, in 80..86, in 95..99 -> true
            else -> false
        }

        private fun fromCloudCover(percent: Int): WeatherCondition = when (percent) {
            in 0..15 -> Clear
            in 16..30 -> MainlyClear
            in 31..55 -> PartlyCloudy
            else -> Overcast
        }
    }
}
