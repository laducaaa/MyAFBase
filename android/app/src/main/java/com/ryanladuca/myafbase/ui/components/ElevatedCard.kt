package com.ryanladuca.myafbase.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.ui.theme.AppTokens
import com.ryanladuca.myafbase.ui.theme.appSemanticColors

@Composable
fun AppCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    cornerRadius: Dp = AppTokens.cardCornerRadius,
    containerColor: Color = MaterialTheme.colorScheme.surface,
    contentPadding: Dp = AppTokens.contentPadding,
    content: @Composable ColumnScope.() -> Unit,
) {
    val dark = isSystemInDarkTheme()
    val shape = RoundedCornerShape(cornerRadius)
    val elevation = if (dark) 0.dp else 1.dp
    val border = if (dark) {
        BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
    } else {
        null
    }
    if (onClick != null) {
        Card(
            onClick = onClick,
            modifier = modifier.fillMaxWidth(),
            shape = shape,
            colors = CardDefaults.cardColors(containerColor = containerColor),
            elevation = CardDefaults.cardElevation(defaultElevation = elevation),
            border = border,
        ) {
            Column(Modifier.padding(contentPadding), content = content)
        }
    } else {
        Card(
            modifier = modifier.fillMaxWidth(),
            shape = shape,
            colors = CardDefaults.cardColors(containerColor = containerColor),
            elevation = CardDefaults.cardElevation(defaultElevation = elevation),
            border = border,
        ) {
            Column(Modifier.padding(contentPadding), content = content)
        }
    }
}

@Composable
fun AppCardNested(
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.small,
    content: @Composable ColumnScope.() -> Unit,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = shape,
        color = appSemanticColors().nestedSurface,
        content = { Column(Modifier.padding(AppTokens.nestedContentPadding), content = content) }
    )
}

@Composable
fun ElevatedSurface(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = AppTokens.cardCornerRadius,
    containerColor: Color = MaterialTheme.colorScheme.surface,
    onClick: (() -> Unit)? = null,
    interactionSource: MutableInteractionSource? = null,
    content: @Composable () -> Unit,
) {
    val dark = isSystemInDarkTheme()
    val shape = RoundedCornerShape(cornerRadius)
    val elevation = if (dark) 0.dp else 1.dp
    val border = if (dark) BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant) else null
    if (onClick != null) {
        Surface(
            onClick = onClick,
            modifier = modifier,
            shape = shape,
            color = containerColor,
            shadowElevation = elevation,
            border = border,
            interactionSource = interactionSource,
            content = content,
        )
    } else {
        Surface(
            modifier = modifier,
            shape = shape,
            color = containerColor,
            shadowElevation = elevation,
            border = border,
            content = content,
        )
    }
}
