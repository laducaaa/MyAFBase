package com.ryanladuca.myafbase.ui.theme

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

object AppButtonDefaults {
    @Composable
    fun primary() = ButtonDefaults.buttonColors(
        containerColor = MaterialTheme.colorScheme.primary,
        contentColor = MaterialTheme.colorScheme.onPrimary,
    )

    @Composable
    fun tonal() = ButtonDefaults.filledTonalButtonColors(
        containerColor = MaterialTheme.colorScheme.secondaryContainer,
        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
    )

    @Composable
    fun outlined() = ButtonDefaults.outlinedButtonColors(
        contentColor = MaterialTheme.colorScheme.onSurface,
    )

    @Composable
    fun text() = ButtonDefaults.textButtonColors(
        contentColor = MaterialTheme.colorScheme.primary,
    )

    @Composable
    fun textNeutral() = ButtonDefaults.textButtonColors(
        contentColor = MaterialTheme.colorScheme.onSurface,
    )

    @Composable
    fun destructive() = ButtonDefaults.buttonColors(
        containerColor = MaterialTheme.colorScheme.error,
        contentColor = MaterialTheme.colorScheme.onError,
    )
}

object AppChipDefaults {
    @Composable
    fun filterChip(selected: Boolean) = FilterChipDefaults.filterChipColors(
        containerColor = MaterialTheme.colorScheme.surfaceVariant,
        labelColor = MaterialTheme.colorScheme.onSurfaceVariant,
        selectedContainerColor = MaterialTheme.colorScheme.secondaryContainer,
        selectedLabelColor = MaterialTheme.colorScheme.onSecondaryContainer,
        iconColor = MaterialTheme.colorScheme.onSurfaceVariant,
        selectedLeadingIconColor = MaterialTheme.colorScheme.onSecondaryContainer,
    )

    @Composable
    fun assistChip() = AssistChipDefaults.assistChipColors(
        containerColor = MaterialTheme.colorScheme.surfaceVariant,
        labelColor = MaterialTheme.colorScheme.onSurfaceVariant,
        leadingIconContentColor = appSemanticColors().accent,
        trailingIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
    )

    @Composable
    fun suggestionChip(containerColor: Color, labelColor: Color) = AssistChipDefaults.assistChipColors(
        containerColor = containerColor,
        labelColor = labelColor,
    )
}

object AppTextFieldDefaults {
    val shape @Composable get() = MaterialTheme.shapes.small

    @Composable
    fun colors() = OutlinedTextFieldDefaults.colors(
        focusedBorderColor = MaterialTheme.colorScheme.primary,
        unfocusedBorderColor = MaterialTheme.colorScheme.outline,
        disabledBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.38f),
        errorBorderColor = MaterialTheme.colorScheme.error,
        focusedLabelColor = MaterialTheme.colorScheme.primary,
        unfocusedLabelColor = MaterialTheme.colorScheme.onSurfaceVariant,
        cursorColor = MaterialTheme.colorScheme.primary,
        focusedTextColor = MaterialTheme.colorScheme.onSurface,
        unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
        focusedContainerColor = MaterialTheme.colorScheme.surface,
        unfocusedContainerColor = MaterialTheme.colorScheme.surface,
        focusedPlaceholderColor = MaterialTheme.colorScheme.onSurfaceVariant,
        unfocusedPlaceholderColor = MaterialTheme.colorScheme.onSurfaceVariant,
        focusedLeadingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
        unfocusedLeadingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
        focusedTrailingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
        unfocusedTrailingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

object AppSwitchDefaults {
    @Composable
    fun colors() = SwitchDefaults.colors(
        checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
        checkedTrackColor = MaterialTheme.colorScheme.primary,
        uncheckedThumbColor = MaterialTheme.colorScheme.outline,
        uncheckedTrackColor = MaterialTheme.colorScheme.surfaceVariant,
        uncheckedBorderColor = MaterialTheme.colorScheme.outline,
    )
}

object AppCheckboxDefaults {
    @Composable
    fun colors() = CheckboxDefaults.colors(
        checkedColor = MaterialTheme.colorScheme.primary,
        uncheckedColor = MaterialTheme.colorScheme.onSurfaceVariant,
        checkmarkColor = MaterialTheme.colorScheme.onPrimary,
    )
}

object AppNavigationDefaults {
    @Composable
    fun navigationBarItemColors() = NavigationBarItemDefaults.colors(
        selectedIconColor = MaterialTheme.colorScheme.onSecondaryContainer,
        selectedTextColor = MaterialTheme.colorScheme.onSecondaryContainer,
        indicatorColor = MaterialTheme.colorScheme.secondaryContainer,
        unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
        unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

object AppTopAppBarDefaults {
    @Composable
    fun centerAlignedColors() = TopAppBarDefaults.centerAlignedTopAppBarColors(
        containerColor = MaterialTheme.colorScheme.background,
        titleContentColor = MaterialTheme.colorScheme.onBackground,
        navigationIconContentColor = appSemanticColors().accent,
        actionIconContentColor = appSemanticColors().accent,
    )

    @Composable
    fun toolColors() = TopAppBarDefaults.topAppBarColors(
        containerColor = MaterialTheme.colorScheme.background,
        titleContentColor = MaterialTheme.colorScheme.onBackground,
        navigationIconContentColor = appSemanticColors().accent,
        actionIconContentColor = appSemanticColors().accent,
    )
}

object AppListItemDefaults {
    @Composable
    fun colors() = ListItemDefaults.colors(
        containerColor = Color.Transparent,
        headlineColor = MaterialTheme.colorScheme.onSurface,
        supportingColor = MaterialTheme.colorScheme.onSurfaceVariant,
        leadingIconColor = appSemanticColors().accent,
        trailingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
    )

    /** ListItem owns horizontal content insets; parents supply screen/edge padding. */
    val contentPadding = PaddingValues(horizontal = 0.dp, vertical = 0.dp)
}

object AppSegmentedDefaults {
    @Composable
    fun colors() = SegmentedButtonDefaults.colors(
        activeContainerColor = MaterialTheme.colorScheme.secondaryContainer,
        activeContentColor = MaterialTheme.colorScheme.onSecondaryContainer,
        inactiveContainerColor = MaterialTheme.colorScheme.surfaceVariant,
        inactiveContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

object AppDialogDefaults {
    val shape @Composable get() = MaterialTheme.shapes.medium

    @Composable
    fun containerColor() = MaterialTheme.colorScheme.surfaceContainerHigh
}
