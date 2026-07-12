package com.ryanladuca.myafbase.domain.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.ryanladuca.myafbase.ui.theme.BrandPrimary
import com.ryanladuca.myafbase.ui.theme.BrandSecondary
import com.ryanladuca.myafbase.ui.theme.Highlight
import com.ryanladuca.myafbase.ui.theme.Info
import com.ryanladuca.myafbase.ui.theme.Success

data class HomeTool(
    val id: String,
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val tint: Color,
)

object HomeToolsCatalog {
    val all: List<HomeTool> = listOf(
        HomeTool(
            id = HomeToolId.PFRA_SCORE.id,
            title = HomeToolId.PFRA_SCORE.title,
            subtitle = HomeToolId.PFRA_SCORE.subtitle,
            icon = Icons.Default.DirectionsRun,
            tint = Info,
        ),
        HomeTool(
            id = HomeToolId.PFRA_GOAL.id,
            title = HomeToolId.PFRA_GOAL.title,
            subtitle = HomeToolId.PFRA_GOAL.subtitle,
            icon = Icons.Default.TrackChanges,
            tint = BrandPrimary,
        ),
        HomeTool(
            id = HomeToolId.AFI_SEARCH.id,
            title = HomeToolId.AFI_SEARCH.title,
            subtitle = HomeToolId.AFI_SEARCH.subtitle,
            icon = Icons.Default.Search,
            tint = BrandPrimary,
        ),
        HomeTool(
            id = HomeToolId.WAR_TRACKER.id,
            title = HomeToolId.WAR_TRACKER.title,
            subtitle = HomeToolId.WAR_TRACKER.subtitle,
            icon = Icons.Default.Star,
            tint = BrandSecondary,
        ),
        HomeTool(
            id = HomeToolId.LEAVE_PLANNER.id,
            title = HomeToolId.LEAVE_PLANNER.title,
            subtitle = HomeToolId.LEAVE_PLANNER.subtitle,
            icon = Icons.Default.CalendarMonth,
            tint = Success,
        ),
        HomeTool(
            id = HomeToolId.PAY_CALENDAR.id,
            title = HomeToolId.PAY_CALENDAR.title,
            subtitle = HomeToolId.PAY_CALENDAR.subtitle,
            icon = Icons.Default.AttachMoney,
            tint = Highlight,
        ),
    )
}
