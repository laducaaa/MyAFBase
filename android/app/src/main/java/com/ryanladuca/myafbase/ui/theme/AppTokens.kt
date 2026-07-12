package com.ryanladuca.myafbase.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

object AppTokens {
    /** 4dp grid — screen / section / card / in-card rhythm. */
    val microGap: Dp = 4.dp
    val screenPadding: Dp = 16.dp
    val sectionSpacing: Dp = 24.dp
    val cardSpacing: Dp = 12.dp
    val contentPadding: Dp = 16.dp
    val nestedContentPadding: Dp = 12.dp

    val cardCornerRadius: Dp = 12.dp
    val heroCornerRadius: Dp = 16.dp
    val innerCornerRadius: Dp = 8.dp

    const val cardShadowOpacity = 0.07f
    val cardShadowRadius: Dp = 8.dp
    val cardShadowY: Dp = 3.dp
    const val heroShadowOpacity = 0.38f
    val heroShadowRadius: Dp = 14.dp
    val heroShadowY: Dp = 8.dp

    val iconBadgeDefault: Dp = 44.dp
    val iconBadgeBento: Dp = 38.dp
    val iconBadgeMenu: Dp = 36.dp
    val iconBadgeList: Dp = 28.dp

    val bentoTileHeight: Dp = 96.dp
    val bentoGridGap: Dp = 12.dp
}

@Immutable
data class AppSemanticColors(
    val accent: Color,
    val accentLight: Color,
    val brandPrimary: Color,
    val brandSecondary: Color,
    val brandSecondaryLight: Color,
    val success: Color,
    val warning: Color,
    val danger: Color,
    val info: Color,
    val muted: Color,
    val highlight: Color,
    val onBrand: Color,
    val heroBackground: Color,
    val heroSecondaryText: Color,
    val heroDivider: Color,
    val cardStroke: Color,
    val nestedSurface: Color,
)

internal val LightSemantic = AppSemanticColors(
    accent = BrandPrimary,
    accentLight = Color(0xFF48B0FF),
    brandPrimary = BrandPrimary,
    brandSecondary = BrandSecondary,
    brandSecondaryLight = Color(0xFF3ED8E8),
    success = Success,
    warning = Warning,
    danger = Danger,
    info = Info,
    muted = Color(0xFF8E8E93),
    highlight = Highlight,
    onBrand = Color.White,
    heroBackground = HeroBackground,
    heroSecondaryText = Color.White.copy(alpha = 0.78f),
    heroDivider = Color.White.copy(alpha = 0.14f),
    cardStroke = Color(0xFF1C1B1F).copy(alpha = 0.08f),
    nestedSurface = Color(0xFFF2F2F7),
)

internal val DarkSemantic = AppSemanticColors(
    accent = BrandPrimaryDark,
    accentLight = Color(0xFF8AD4FF),
    brandPrimary = BrandPrimaryDark,
    brandSecondary = BrandSecondaryDark,
    brandSecondaryLight = Color(0xFF68E8F4),
    success = Color(0xFF58E0A0),
    warning = Color(0xFFF0A830),
    danger = Color(0xFFF06B6B),
    info = Color(0xFF78C8FF),
    muted = Color(0xFF98989D),
    highlight = Color(0xFFFFE040),
    onBrand = Color.White,
    heroBackground = HeroBackgroundDark,
    heroSecondaryText = Color.White.copy(alpha = 0.78f),
    heroDivider = Color.White.copy(alpha = 0.14f),
    cardStroke = Color.White.copy(alpha = 0.08f),
    nestedSurface = Color(0xFF2C2C2E),
)

val LocalAppSemanticColors = staticCompositionLocalOf { LightSemantic }

@Composable
fun rememberAppSemanticColors(): AppSemanticColors =
    if (isSystemInDarkTheme()) DarkSemantic else LightSemantic

@Composable
fun appSemanticColors(): AppSemanticColors = LocalAppSemanticColors.current
