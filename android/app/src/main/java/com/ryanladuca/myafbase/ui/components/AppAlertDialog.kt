package com.ryanladuca.myafbase.ui.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.ryanladuca.myafbase.ui.theme.AppButtonDefaults
import com.ryanladuca.myafbase.ui.theme.AppDialogDefaults

@Composable
fun AppAlertDialog(
    title: String,
    text: String,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    confirmText: String? = null,
    onConfirm: (() -> Unit)? = null,
    dismissText: String = "Cancel",
    destructiveConfirm: Boolean = false,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        modifier = modifier,
        shape = AppDialogDefaults.shape,
        containerColor = AppDialogDefaults.containerColor(),
        title = {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineSmall,
            )
        },
        text = {
            Text(
                text = text,
                style = MaterialTheme.typography.bodyMedium,
            )
        },
        confirmButton = {
            if (confirmText != null && onConfirm != null) {
                if (destructiveConfirm) {
                    TextButton(
                        onClick = onConfirm,
                        colors = AppButtonDefaults.text(),
                    ) {
                        Text(confirmText, color = MaterialTheme.colorScheme.error)
                    }
                } else {
                    FilledTonalButton(
                        onClick = onConfirm,
                        colors = AppButtonDefaults.tonal(),
                    ) {
                        Text(confirmText)
                    }
                }
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                colors = AppButtonDefaults.textNeutral(),
            ) {
                Text(dismissText)
            }
        },
    )
}
