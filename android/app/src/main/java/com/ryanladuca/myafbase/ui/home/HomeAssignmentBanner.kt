package com.ryanladuca.myafbase.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.data.db.AssignmentProfileEntity
import com.ryanladuca.myafbase.domain.model.AssignmentSegment
import java.util.Calendar
import java.util.concurrent.TimeUnit

@Composable
fun HomeAssignmentBanner(
    baseName: String,
    profile: AssignmentProfileEntity?,
    onOpenAssignment: () -> Unit,
) {
    val message = bannerMessage(baseName, profile) ?: return
    val scheme = MaterialTheme.colorScheme
    val phase = AssignmentSegment.fromRaw(profile?.phaseRaw)
    val containerColor = when (phase) {
        AssignmentSegment.INBOUND -> scheme.tertiaryContainer
        AssignmentSegment.STATIONED -> scheme.primaryContainer
        AssignmentSegment.OUTBOUND -> scheme.secondaryContainer
    }
    val contentColor = when (phase) {
        AssignmentSegment.INBOUND -> scheme.onTertiaryContainer
        AssignmentSegment.STATIONED -> scheme.onPrimaryContainer
        AssignmentSegment.OUTBOUND -> scheme.onSecondaryContainer
    }
    Surface(
        onClick = onOpenAssignment,
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = containerColor,
        tonalElevation = 0.dp,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = contentColor.copy(alpha = 0.12f),
                tonalElevation = 0.dp,
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Assignment,
                    contentDescription = null,
                    tint = contentColor,
                    modifier = Modifier
                        .padding(10.dp)
                        .size(20.dp),
                )
            }
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    message.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = contentColor,
                )
                Text(
                    message.subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = contentColor.copy(alpha = 0.82f),
                )
            }
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = contentColor,
            )
        }
    }
}

private data class BannerMessage(val title: String, val subtitle: String)

private fun bannerMessage(baseName: String, profile: AssignmentProfileEntity?): BannerMessage? {
    val phase = AssignmentSegment.fromRaw(profile?.phaseRaw)
    return when (phase) {
        AssignmentSegment.INBOUND -> profile?.reportDateMillis?.let { date ->
            BannerMessage(
                countdownTitle("Report", date),
                "In processing at $baseName · open Assignment for your checklist.",
            )
        }
        AssignmentSegment.OUTBOUND -> profile?.pcsDateMillis?.let { date ->
            BannerMessage(
                countdownTitle("PCS", date),
                "Out processing from $baseName · use Leave Planner to check balances.",
            )
        }
        AssignmentSegment.STATIONED -> profile?.pcsDateMillis?.let { date ->
            val days = daysUntil(date)
            if (days in 0..120) {
                BannerMessage(
                    countdownTitle("PCS", date),
                    "Planning ahead · set phase to Out Processing when out-processing starts.",
                )
            } else null
        }
    }
}

private fun daysUntil(millis: Long): Int {
    val now = startOfDay(System.currentTimeMillis())
    val target = startOfDay(millis)
    return TimeUnit.MILLISECONDS.toDays(target - now).toInt()
}

private fun startOfDay(millis: Long): Long {
    val cal = Calendar.getInstance().apply { timeInMillis = millis }
    cal.set(Calendar.HOUR_OF_DAY, 0)
    cal.set(Calendar.MINUTE, 0)
    cal.set(Calendar.SECOND, 0)
    cal.set(Calendar.MILLISECOND, 0)
    return cal.timeInMillis
}

private fun countdownTitle(subject: String, dateMillis: Long): String {
    val days = daysUntil(dateMillis)
    return when {
        days < 0 -> "$subject was ${-days} days ago"
        days == 0 -> "$subject is today"
        days == 1 -> "$subject in 1 day"
        else -> "$subject in $days days"
    }
}
