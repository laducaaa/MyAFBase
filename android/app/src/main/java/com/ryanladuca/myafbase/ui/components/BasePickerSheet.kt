package com.ryanladuca.myafbase.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.logic.BaseCatalog
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.theme.AppListItemDefaults
import com.ryanladuca.myafbase.ui.theme.AppTextFieldDefaults
import com.ryanladuca.myafbase.ui.theme.AppTokens
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BasePickerSheet(
    onDismiss: () -> Unit,
    onSelected: (String) -> Unit
) {
    val appState = LocalAppState.current
    val index by appState.index.collectAsState()
    var query by remember { mutableStateOf("") }
    val bases = remember(index, query) {
        BaseCatalog.conusBases(index).filter {
            query.isBlank() ||
                it.name.contains(query, ignoreCase = true) ||
                it.location.contains(query, ignoreCase = true) ||
                it.wing.contains(query, ignoreCase = true)
        }
    }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        dragHandle = { SheetDragHandle() },
        containerColor = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AppTokens.screenPadding),
            verticalArrangement = Arrangement.spacedBy(AppTokens.innerCornerRadius)
        ) {
            Text("Select base", style = MaterialTheme.typography.titleLarge)
            Text(
                "CONUS installations available in the picker. OCONUS data remains in the catalog for later.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                placeholder = { Text("Search bases") },
                singleLine = true,
                shape = AppTextFieldDefaults.shape,
                colors = AppTextFieldDefaults.colors(),
            )
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 32.dp)
            ) {
                items(bases, key = { it.id }) { entry ->
                    ListItem(
                        headlineContent = { Text(entry.name) },
                        supportingContent = {
                            Text("${entry.location} · ${entry.wing}".uppercase(Locale.US))
                        },
                        colors = AppListItemDefaults.colors(),
                        modifier = Modifier.clickable {
                            onSelected(entry.id)
                            onDismiss()
                        }
                    )
                }
            }
        }
    }
}
