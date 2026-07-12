package com.ryanladuca.myafbase.ui.menu

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.AssignmentProfileEntity
import com.ryanladuca.myafbase.domain.model.AssignmentSegment
import com.ryanladuca.myafbase.ui.LocalAppContainer
import com.ryanladuca.myafbase.ui.components.AppSegmentedControl
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch

@Composable
fun MenuAssignmentPhaseRow(
    baseId: String,
    phase: AssignmentSegment,
    onPhaseChanged: (AssignmentSegment) -> Unit,
) {
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val labels = listOf("In", "Stationed", "Out")
    val selectedIndex = AssignmentSegment.entries.indexOf(phase).coerceAtLeast(0)

    Column(
        verticalArrangement = Arrangement.spacedBy(AppTokens.microGap + 2.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text("Assignment phase", style = MaterialTheme.typography.titleSmall)
        AppSegmentedControl(
            options = labels,
            selectedIndex = selectedIndex,
            onSelected = { index ->
                val segment = AssignmentSegment.entries[index]
                scope.launch {
                    val current = container.database.assignmentDao().get(baseId)
                    container.database.assignmentDao().upsert(
                        AssignmentProfileEntity(
                            baseId = baseId,
                            phaseRaw = segment.raw,
                            reportDateMillis = current?.reportDateMillis,
                            pcsDateMillis = current?.pcsDateMillis,
                            updatedAtMillis = System.currentTimeMillis(),
                        ),
                    )
                    onPhaseChanged(segment)
                }
            },
            equalWidth = true,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
