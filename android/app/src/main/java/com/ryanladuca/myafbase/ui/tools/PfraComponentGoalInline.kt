package com.ryanladuca.myafbase.ui.tools

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.domain.logic.PFRAComponentTarget

@Composable
fun PfraComponentGoalInline(target: PFRAComponentTarget) {
    val isCardio = target.name == "Cardio"
    val gapText = if (target.needsImprovement) {
        "+${formatPoints(target.pointsGap, isCardio)} pts"
    } else {
        "On track"
    }
    val progress = if (target.requiredPoints > 0) {
        (target.currentPoints / target.requiredPoints).coerceIn(0.0, 1.0).toFloat()
    } else 0f

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                "${formatPoints(target.currentPoints, isCardio)} / ${formatPoints(target.requiredPoints, isCardio)} goal",
                fontWeight = FontWeight.SemiBold
            )
            Surface(
                color = if (target.needsImprovement) {
                    MaterialTheme.colorScheme.errorContainer
                } else {
                    MaterialTheme.colorScheme.primaryContainer
                },
                shape = MaterialTheme.shapes.small
            ) {
                Text(
                    gapText,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }
        LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth())
        Text(
            target.currentDetail,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        if (target.needsImprovement) {
            Text(
                actionableTarget(target.targetDetail),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

private fun formatPoints(value: Double, isCardio: Boolean): String =
    if (isCardio) value.toInt().toString() else "%.1f".format(value)

private fun actionableTarget(detail: String): String {
    val marker = " ("
    val index = detail.lastIndexOf(marker)
    return if (index > 0) detail.substring(0, index) else detail
}
