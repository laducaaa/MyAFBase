package com.ryanladuca.myafbase.ui.explore

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Dining
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Park
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.VolunteerActivism
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

data class ExploreCategory(
    val id: String,
    val label: String,
    val icon: ImageVector,
)

private val resourceCategories = listOf(
    ExploreCategory("all", "All", Icons.Default.MoreHoriz),
    ExploreCategory("gates", "Gates", Icons.Default.DirectionsCar),
    ExploreCategory("dining", "Dining", Icons.Default.Dining),
    ExploreCategory("medical", "Medical", Icons.Default.LocalHospital),
    ExploreCategory("shopping", "Shop", Icons.Default.ShoppingBag),
    ExploreCategory("finance", "Finance", Icons.Default.VolunteerActivism),
    ExploreCategory("housing", "Housing", Icons.Default.Home),
    ExploreCategory("fitness", "Fitness", Icons.Default.FitnessCenter),
    ExploreCategory("services", "Services", Icons.Default.MoreHoriz),
    ExploreCategory("recreation", "Rec", Icons.Default.Park),
    ExploreCategory("safety", "Safety", Icons.Default.Security),
)

private val eventCategories = listOf(
    ExploreCategory("all", "All", Icons.Default.MoreHoriz),
    ExploreCategory("holiday", "Holiday", Icons.Default.CalendarMonth),
    ExploreCategory("family", "Family", Icons.Default.VolunteerActivism),
    ExploreCategory("outdoor", "Outdoor", Icons.Default.Park),
    ExploreCategory("community", "Community", Icons.Default.VolunteerActivism),
    ExploreCategory("fitness", "Fitness", Icons.Default.FitnessCenter),
)

@Composable
fun ExploreCategoryBar(
    categories: List<ExploreCategory>,
    selectedId: String,
    onSelected: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val scheme = MaterialTheme.colorScheme
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        categories.forEach { cat ->
            val selected = cat.id == selectedId
            FilterChip(
                selected = selected,
                onClick = { onSelected(cat.id) },
                label = { Text(cat.label) },
                leadingIcon = {
                    Icon(
                        imageVector = cat.icon,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                    )
                },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = scheme.secondaryContainer,
                    selectedLabelColor = scheme.onSecondaryContainer,
                    selectedLeadingIconColor = scheme.onSecondaryContainer,
                ),
            )
        }
    }
}

fun exploreResourceCategories() = resourceCategories

fun exploreEventCategories() = eventCategories

fun exploreCategoryIcon(categoryId: String, isEvents: Boolean): ImageVector {
    val categories = if (isEvents) eventCategories else resourceCategories
    return categories.find { it.id.equals(categoryId, ignoreCase = true) }?.icon ?: Icons.Default.Place
}
