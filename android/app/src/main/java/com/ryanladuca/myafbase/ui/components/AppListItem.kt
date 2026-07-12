package com.ryanladuca.myafbase.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import com.ryanladuca.myafbase.ui.theme.AppListItemDefaults

/**
 * List chrome aligned to Material 3 [ListItem] insets.
 * Parents own screen-edge padding ([AppTokens.screenPadding]); this item does not add a second layer.
 */
@Composable
fun AppListItem(
    headline: String,
    modifier: Modifier = Modifier,
    supporting: String? = null,
    leading: @Composable (() -> Unit)? = null,
    trailing: @Composable (() -> Unit)? = null,
    onClick: (() -> Unit)? = null,
) {
    val itemModifier = if (onClick != null) {
        modifier
            .clickable(onClick = onClick)
            .semantics { role = Role.Button }
    } else {
        modifier
    }
    ListItem(
        headlineContent = {
            Text(
                text = headline,
                style = MaterialTheme.typography.titleSmall,
            )
        },
        supportingContent = supporting?.let {
            {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        leadingContent = leading,
        trailingContent = trailing,
        colors = AppListItemDefaults.colors(),
        modifier = itemModifier,
    )
}
