package com.ryanladuca.myafbase.ui.onboarding

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ryanladuca.myafbase.ui.LocalAppState
import com.ryanladuca.myafbase.ui.theme.AppCheckboxDefaults
import com.ryanladuca.myafbase.ui.theme.AppMotion
import com.ryanladuca.myafbase.ui.theme.AppTokens
import kotlinx.coroutines.launch

private data class OnboardingPage(val eyebrow: String, val title: String, val body: String)

@Composable
fun OnboardingScreen(onFinished: () -> Unit) {
    val appState = LocalAppState.current
    val scheme = MaterialTheme.colorScheme
    val canvas = scheme.surface
    val ink = scheme.onSurface
    val muted = scheme.onSurfaceVariant
    val pages = listOf(
        OnboardingPage("EXPLORE", "Explore your base", "Browse gates, resources, and events. Filter what's open now and save bookmarks for quick access."),
        OnboardingPage("TOOLS", "Tools that travel with you", "PFRA scoring, leave and pay planning, WAR logging, and essential AFI search — built for day-to-day Air Force life."),
        OnboardingPage("ASSIGNMENT", "Assignment clarity", "Track in-processing, stationed life, and out-processing with checklists, dates, and readiness reminders."),
        OnboardingPage("LEGAL", "Before you continue", "MyAFBase is an independent community tool. It is not affiliated with, endorsed by, or an official product of the DoD or U.S. Air Force. Do not submit PII or sensitive information."),
    )
    val pagerState = rememberPagerState(pageCount = { pages.size })
    val scope = rememberCoroutineScope()
    var legalAck by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier.fillMaxSize().background(canvas).padding(AppTokens.sectionSpacing),
        verticalArrangement = Arrangement.spacedBy(AppTokens.screenPadding),
    ) {
        Text("MYAFBASE", style = MaterialTheme.typography.labelLarge, color = muted, fontWeight = FontWeight.SemiBold)
        HorizontalPager(state = pagerState, modifier = Modifier.weight(1f)) { page ->
            val alpha by animateFloatAsState(1f, animationSpec = AppMotion.onboardingRevealSpring, label = "onboardAlpha")
            Column(
                modifier = Modifier.fillMaxSize().alpha(alpha).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(AppTokens.cardSpacing),
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(180.dp)
                        .background(Brush.verticalGradient(listOf(ink.copy(alpha = 0.08f), canvas.copy(alpha = 0f)))),
                )
                Text(pages[page].eyebrow, color = muted, style = MaterialTheme.typography.labelMedium)
                Text(pages[page].title, style = MaterialTheme.typography.headlineMedium, color = ink, fontWeight = FontWeight.Bold)
                Text(pages[page].body, style = MaterialTheme.typography.bodyLarge, color = muted)
                if (page == pages.lastIndex) {
                    Row(verticalAlignment = Alignment.Top) {
                        Checkbox(
                            checked = legalAck,
                            onCheckedChange = { legalAck = it },
                            colors = AppCheckboxDefaults.colors(),
                        )
                        Text(
                            "I understand MyAFBase is unofficial, not affiliated with the DoD or U.S. Air Force, and I will not submit PII or sensitive information through the app.",
                            color = ink.copy(alpha = 0.8f),
                        )
                    }
                }
            }
        }
        val isLast = pagerState.currentPage == pages.lastIndex
        Button(
            onClick = {
                if (isLast) {
                    scope.launch {
                        appState.completeOnboarding()
                        onFinished()
                    }
                } else {
                    scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                }
            },
            enabled = !isLast || legalAck,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = ink, contentColor = canvas),
            shape = MaterialTheme.shapes.medium,
        ) {
            Text(if (isLast) "Choose My Base" else "Continue")
        }
        if (!isLast) {
            TextButton(
                onClick = { scope.launch { pagerState.animateScrollToPage(pages.lastIndex) } },
                colors = ButtonDefaults.textButtonColors(contentColor = muted),
            ) {
                Text("Skip to legal", color = muted)
            }
        }
    }
}
