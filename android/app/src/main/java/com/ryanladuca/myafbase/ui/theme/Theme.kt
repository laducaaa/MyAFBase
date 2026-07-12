package com.ryanladuca.myafbase.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

val BrandPrimary = Color(0xFF2898EB)
val BrandPrimaryDark = Color(0xFF6EC2FF)
val BrandSecondary = Color(0xFF1EC4D4)
val BrandSecondaryDark = Color(0xFF48DDE8)
val Success = Color(0xFF30C97E)
val Warning = Color(0xFFC97814)
val Danger = Color(0xFFC23B3B)
val Info = Color(0xFF38A8F8)
val Highlight = Color(0xFFFFC800)
val HeroBackground = Color(0xFF1E1E20)
val HeroBackgroundDark = Color(0xFF121214)

private val LightGroupedBackground = Color(0xFFF2F2F7)
private val LightSurface = Color(0xFFFFFFFF)
private val LightSurfaceVariant = Color(0xFFE8E8ED)
private val LightInk = Color(0xFF1C1B1F)

private val DarkGroupedBackground = HeroBackgroundDark
private val DarkSurface = Color(0xFF1C1C1E)
private val DarkSurfaceVariant = Color(0xFF2C2C2E)
private val DarkInk = Color(0xFFE8E8EA)

/** Mix two locked-palette colors; [ratio] is weight of [other] (0 = this, 1 = other). */
internal fun Color.mix(other: Color, ratio: Float): Color {
    val t = ratio.coerceIn(0f, 1f)
    return Color(
        red = red + (other.red - red) * t,
        green = green + (other.green - green) * t,
        blue = blue + (other.blue - blue) * t,
        alpha = alpha + (other.alpha - alpha) * t,
    )
}

private val LightColors = lightColorScheme(
    primary = BrandPrimary,
    onPrimary = Color.White,
    primaryContainer = BrandPrimary.mix(Color.White, 0.84f),
    onPrimaryContainer = BrandPrimary.mix(LightInk, 0.55f),
    secondary = BrandSecondary,
    onSecondary = Color.White,
    secondaryContainer = BrandSecondary.mix(Color.White, 0.84f),
    onSecondaryContainer = BrandSecondary.mix(LightInk, 0.55f),
    tertiary = Info,
    onTertiary = Color.White,
    tertiaryContainer = Info.mix(Color.White, 0.84f),
    onTertiaryContainer = Info.mix(LightInk, 0.52f),
    error = Danger,
    onError = Color.White,
    errorContainer = Danger.mix(Color.White, 0.86f),
    onErrorContainer = Danger.mix(LightInk, 0.42f),
    background = LightGroupedBackground,
    onBackground = LightInk,
    surface = LightSurface,
    onSurface = LightInk,
    surfaceVariant = LightSurfaceVariant,
    onSurfaceVariant = Color(0xFF49454F),
    outline = Color(0xFF79747E),
    outlineVariant = LightInk.copy(alpha = 0.12f),
    scrim = Color.Black.copy(alpha = 0.32f),
    inverseSurface = DarkSurface,
    inverseOnSurface = DarkInk,
    inversePrimary = BrandPrimaryDark,
    surfaceContainerLowest = Color.White,
    surfaceContainerLow = Color(0xFFF7F7FA),
    surfaceContainer = LightSurface,
    surfaceContainerHigh = LightSurfaceVariant,
    surfaceContainerHighest = Color(0xFFE3E3E8),
)

private val DarkColors = darkColorScheme(
    primary = BrandPrimaryDark,
    onPrimary = Color(0xFF00344F),
    primaryContainer = BrandPrimary.mix(DarkSurface, 0.62f),
    onPrimaryContainer = BrandPrimaryDark.mix(Color.White, 0.18f),
    secondary = BrandSecondaryDark,
    onSecondary = Color(0xFF00363B),
    secondaryContainer = BrandSecondary.mix(DarkSurface, 0.62f),
    onSecondaryContainer = BrandSecondaryDark.mix(Color.White, 0.18f),
    tertiary = Color(0xFF78C8FF),
    onTertiary = Color(0xFF00344F),
    tertiaryContainer = Info.mix(DarkSurface, 0.62f),
    onTertiaryContainer = Color(0xFF78C8FF).mix(Color.White, 0.15f),
    error = Color(0xFFF06B6B),
    onError = Color(0xFF601410),
    errorContainer = Danger.mix(DarkSurface, 0.55f),
    onErrorContainer = Color(0xFFF06B6B).mix(Color.White, 0.2f),
    background = DarkGroupedBackground,
    onBackground = DarkInk,
    surface = DarkSurface,
    onSurface = DarkInk,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = Color(0xFFCAC4D0),
    outline = Color(0xFF938F99),
    outlineVariant = Color.White.copy(alpha = 0.12f),
    scrim = Color.Black.copy(alpha = 0.6f),
    inverseSurface = LightSurfaceVariant,
    inverseOnSurface = LightInk,
    inversePrimary = BrandPrimary,
    surfaceContainerLowest = HeroBackgroundDark,
    surfaceContainerLow = Color(0xFF161618),
    surfaceContainer = DarkSurface,
    surfaceContainerHigh = DarkSurfaceVariant,
    surfaceContainerHighest = Color(0xFF3A3A3C),
)

private fun semanticFromScheme(scheme: ColorScheme, darkTheme: Boolean): AppSemanticColors {
    return if (darkTheme) {
        AppSemanticColors(
            accent = scheme.primary,
            accentLight = scheme.primary.mix(Color.White, 0.2f),
            brandPrimary = scheme.primary,
            brandSecondary = scheme.secondary,
            brandSecondaryLight = scheme.secondary.mix(Color.White, 0.2f),
            success = Color(0xFF58E0A0),
            warning = Color(0xFFF0A830),
            danger = Color(0xFFF06B6B),
            info = scheme.tertiary,
            muted = Color(0xFF98989D),
            highlight = Color(0xFFFFE040),
            onBrand = scheme.onPrimary,
            heroBackground = HeroBackgroundDark,
            heroSecondaryText = Color.White.copy(alpha = 0.78f),
            heroDivider = Color.White.copy(alpha = 0.14f),
            cardStroke = Color.White.copy(alpha = 0.08f),
            nestedSurface = scheme.surfaceContainerHigh,
        )
    } else {
        AppSemanticColors(
            accent = scheme.primary,
            accentLight = scheme.primary.mix(Color.White, 0.15f),
            brandPrimary = scheme.primary,
            brandSecondary = scheme.secondary,
            brandSecondaryLight = scheme.secondary.mix(Color.White, 0.15f),
            success = Success,
            warning = Warning,
            danger = Danger,
            info = scheme.tertiary,
            muted = Color(0xFF8E8E93),
            highlight = Highlight,
            onBrand = scheme.onPrimary,
            heroBackground = HeroBackground,
            heroSecondaryText = Color.White.copy(alpha = 0.78f),
            heroDivider = Color.White.copy(alpha = 0.14f),
            cardStroke = LightInk.copy(alpha = 0.08f),
            nestedSurface = scheme.surfaceContainerLow,
        )
    }
}

@Composable
fun MyAFBaseTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val useDynamicColor = dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    val colorScheme = when {
        useDynamicColor && darkTheme -> dynamicDarkColorScheme(context)
        useDynamicColor -> dynamicLightColorScheme(context)
        darkTheme -> DarkColors
        else -> LightColors
    }
    val semantic = if (useDynamicColor) {
        semanticFromScheme(colorScheme, darkTheme)
    } else if (darkTheme) {
        DarkSemantic
    } else {
        LightSemantic
    }
    CompositionLocalProvider(LocalAppSemanticColors provides semantic) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = Typography,
            shapes = AppShapes,
            content = content,
        )
    }
}
