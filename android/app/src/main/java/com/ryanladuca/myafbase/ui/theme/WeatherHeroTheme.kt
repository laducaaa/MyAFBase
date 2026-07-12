package com.ryanladuca.myafbase.ui.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AcUnit
import androidx.compose.material.icons.filled.Apartment
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.Grain
import androidx.compose.material.icons.filled.Thunderstorm
import androidx.compose.material.icons.filled.WbCloudy
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

data class WeatherHeroPalette(
    val colors: List<Color>,
    val glow: Color,
    val symbol: ImageVector,
    val symbolOpacity: Float,
)

object WeatherHeroTheme {
    fun palette(themeKey: String?): WeatherHeroPalette {
        return when (themeKey?.lowercase()) {
            "clear" -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF48B0FF),
                    Color(0xFF2898EB),
                    Color(0xFF1A9FD4),
                ),
                glow = Color(0xFFFFC800),
                symbol = Icons.Default.WbSunny,
                symbolOpacity = 0.18f,
            )
            "partly cloudy" -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF38A8F8),
                    Color(0xFF2898EB),
                    Color(0xFF1E1E20),
                ),
                glow = Color(0xFF6EC2FF),
                symbol = Icons.Default.WbCloudy,
                symbolOpacity = 0.16f,
            )
            "cloudy" -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF8E8E93),
                    Color(0xFF1E1E20),
                    Color(0xFF121214),
                ),
                glow = Color(0xFF98989D),
                symbol = Icons.Default.Cloud,
                symbolOpacity = 0.14f,
            )
            "rain" -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF2088F0),
                    Color(0xFF2898EB),
                    Color(0xFF121214),
                ),
                glow = Color(0xFF6EC2FF),
                symbol = Icons.Default.Grain,
                symbolOpacity = 0.15f,
            )
            "snow" -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF3ED8E8),
                    Color(0xFF38A8F8),
                    Color(0xFF2898EB),
                ),
                glow = Color(0xFF8AD4FF),
                symbol = Icons.Default.AcUnit,
                symbolOpacity = 0.16f,
            )
            "fog" -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF8E8E93),
                    Color(0xFF1E1E20),
                ),
                glow = Color(0xFF98989D),
                symbol = Icons.Default.Cloud,
                symbolOpacity = 0.14f,
            )
            "thunderstorm" -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF5E63F0),
                    Color(0xFF787DF8),
                    Color(0xFF121214),
                ),
                glow = Color(0xFF7B80FF),
                symbol = Icons.Default.Thunderstorm,
                symbolOpacity = 0.16f,
            )
            else -> WeatherHeroPalette(
                colors = listOf(
                    Color(0xFF1E1E20),
                    Color(0xFF121214),
                ),
                glow = Color(0xFF6EC2FF),
                symbol = Icons.Default.Apartment,
                symbolOpacity = 0.10f,
            )
        }
    }
}
