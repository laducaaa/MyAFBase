package com.ryanladuca.myafbase.ui.theme

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween

object AppMotion {
    const val bentoPressScale = 0.97f
    const val bentoPressAlpha = 0.92f
    val bentoPressSpring = spring<Float>(
        dampingRatio = 0.72f,
        stiffness = Spring.StiffnessMediumLow
    )

    val accordionTween = tween<Float>(durationMillis = 200)
    val scoreBarTween = tween<Float>(durationMillis = 200)

    const val exploreStaggerMs = 45L
    val exploreRevealSpring = spring<Float>(
        dampingRatio = 0.74f,
        stiffness = Spring.StiffnessMedium
    )

    const val reminderDismissScale = 0.94f
    val reminderDismissSpring = spring<Float>(
        dampingRatio = 0.84f,
        stiffness = Spring.StiffnessMedium
    )

    val segmentToggleSpring = spring<Float>(
        dampingRatio = 0.8f,
        stiffness = Spring.StiffnessMediumLow
    )

    val onboardingRevealSpring = spring<Float>(
        dampingRatio = 0.86f,
        stiffness = Spring.StiffnessLow
    )
    const val onboardingStaggerMs = 70L
}
