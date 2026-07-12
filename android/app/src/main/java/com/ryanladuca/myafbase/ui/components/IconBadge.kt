package com.ryanladuca.myafbase.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

enum class IconBadgeStyle { Tinted, Solid }

@Composable
fun IconBadge(
    icon: ImageVector,
    tint: Color,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp,
    style: IconBadgeStyle = IconBadgeStyle.Tinted,
    contentDescription: String? = null,
) {
    val cornerRadius = size * 0.27f
    val iconSize = size * 0.4f
    Box(
        modifier = modifier
            .size(size)
            .clip(RoundedCornerShape(cornerRadius))
            .then(
                if (style == IconBadgeStyle.Solid) {
                    Modifier.background(Brush.linearGradient(listOf(tint, tint.copy(alpha = 0.85f))))
                } else {
                    Modifier.background(tint.copy(alpha = 0.22f))
                }
            ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = if (style == IconBadgeStyle.Solid) Color.White else tint,
            modifier = Modifier.size(iconSize),
        )
    }
}

@Composable
fun IconBadge(
    icon: ImageVector,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp,
    style: IconBadgeStyle = IconBadgeStyle.Tinted,
    contentDescription: String? = null,
) {
    IconBadge(
        icon = icon,
        tint = MaterialTheme.colorScheme.primary,
        modifier = modifier,
        size = size,
        style = style,
        contentDescription = contentDescription,
    )
}
