import Foundation
import Testing
@testable import MyAFBase

struct WeatherHeroThemeTests {
    @Test func clearUsesSunnyPalette() {
        let palette = WeatherHeroTheme.palette(for: "Clear")
        #expect(palette.symbol == "sun.max.fill")
        #expect(palette.colors.count == 3)
    }

    @Test func rainUsesRainPalette() {
        let palette = WeatherHeroTheme.palette(for: "rain")
        #expect(palette.symbol == "cloud.rain.fill")
    }

    @Test func thunderstormUsesStormPalette() {
        let palette = WeatherHeroTheme.palette(for: "thunderstorm")
        #expect(palette.symbol == "cloud.bolt.rain.fill")
    }

    @Test func unknownFallsBackToNeutralPalette() {
        let palette = WeatherHeroTheme.palette(for: "Unavailable")
        #expect(palette.symbol == "building.2.fill")
    }
}
