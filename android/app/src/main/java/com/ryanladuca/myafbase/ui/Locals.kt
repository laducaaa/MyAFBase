package com.ryanladuca.myafbase.ui

import androidx.compose.runtime.staticCompositionLocalOf
import com.ryanladuca.myafbase.data.AppContainer
import com.ryanladuca.myafbase.data.AppState

val LocalAppContainer = staticCompositionLocalOf<AppContainer> {
    error("AppContainer not provided")
}

val LocalAppState = staticCompositionLocalOf<AppState> {
    error("AppState not provided")
}
