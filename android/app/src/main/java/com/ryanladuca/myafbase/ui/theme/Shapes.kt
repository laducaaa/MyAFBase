package com.ryanladuca.myafbase.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

val AppShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),
    small = RoundedCornerShape(AppTokens.innerCornerRadius),
    medium = RoundedCornerShape(AppTokens.cardCornerRadius),
    large = RoundedCornerShape(AppTokens.heroCornerRadius),
    extraLarge = RoundedCornerShape(28.dp),
)
