package com.ryanladuca.myafbase.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.ui.theme.AppTokens

/**
 * Single drag handle for [androidx.compose.material3.ModalBottomSheet].
 * Pass as `dragHandle = { SheetDragHandle() }` — do not also place inside sheet content.
 */
@Composable
fun SheetDragHandle(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = AppTokens.contentPadding),
        contentAlignment = Alignment.Center,
    ) {
        Surface(
            modifier = Modifier
                .height(4.dp)
                .fillMaxWidth(0.12f),
            shape = RoundedCornerShape(50),
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
        ) {}
    }
}
