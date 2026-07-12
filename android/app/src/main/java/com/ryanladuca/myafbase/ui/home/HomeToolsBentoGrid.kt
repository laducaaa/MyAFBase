package com.ryanladuca.myafbase.ui.home

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.model.HomeToolsCatalog
import com.ryanladuca.myafbase.ui.theme.AppMotion
import com.ryanladuca.myafbase.ui.theme.AppTokens

@Composable
fun HomeToolsBentoGrid(
    onOpenTool: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val tools = HomeToolsCatalog.all
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(AppTokens.bentoGridGap),
    ) {
        tools.chunked(2).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(AppTokens.bentoGridGap),
            ) {
                row.forEach { tool ->
                    BentoTile(
                        tool = tool,
                        onClick = { onOpenTool(tool.id) },
                        modifier = Modifier.weight(1f),
                    )
                }
                if (row.size == 1) {
                    Spacer(Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun BentoTile(
    tool: com.ryanladuca.myafbase.domain.model.HomeTool,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scheme = MaterialTheme.colorScheme
    val interactionSource = remember { MutableInteractionSource() }
    val pressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) AppMotion.bentoPressScale else 1f,
        animationSpec = AppMotion.bentoPressSpring,
        label = "bentoScale",
    )
    val alpha by animateFloatAsState(
        targetValue = if (pressed) AppMotion.bentoPressAlpha else 1f,
        animationSpec = AppMotion.bentoPressSpring,
        label = "bentoAlpha",
    )
    Surface(
        onClick = onClick,
        modifier = modifier
            .height(AppTokens.bentoTileHeight)
            .scale(scale)
            .alpha(alpha),
        shape = MaterialTheme.shapes.extraLarge,
        color = scheme.surfaceContainerHigh,
        tonalElevation = 1.dp,
        interactionSource = interactionSource,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(AppTokens.nestedContentPadding),
            verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
        ) {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = scheme.primaryContainer,
                tonalElevation = 0.dp,
            ) {
                Icon(
                    imageVector = tool.icon,
                    contentDescription = null,
                    tint = scheme.onPrimaryContainer,
                    modifier = Modifier
                        .padding(10.dp)
                        .size(AppTokens.iconBadgeBento - 20.dp),
                )
            }
            Text(
                text = tool.title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Medium,
                color = scheme.onSurface,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}
