import SwiftUI

enum WeatherHeroTheme {
    struct Palette {
        let colors: [Color]
        let glow: Color
        let symbol: String
        let symbolOpacity: Double

        var gradient: LinearGradient {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func palette(for condition: String?) -> Palette {
        switch condition?.lowercased() {
        case "clear":
            return Palette(
                colors: [
                    Color(hex: "48B0FF"),
                    Color(hex: "2898EB"),
                    Color(hex: "1A9FD4")
                ],
                glow: Color(hex: "FFC800"),
                symbol: "sun.max.fill",
                symbolOpacity: 0.18
            )
        case "partly cloudy":
            return Palette(
                colors: [
                    Color(hex: "38A8F8"),
                    Color(hex: "2898EB"),
                    Color(hex: "1E1E20")
                ],
                glow: Color(hex: "6EC2FF"),
                symbol: "cloud.sun.fill",
                symbolOpacity: 0.16
            )
        case "cloudy":
            return Palette(
                colors: [
                    Color(hex: "8E8E93"),
                    Color(hex: "1E1E20"),
                    Color(hex: "121214")
                ],
                glow: Color(hex: "98989D"),
                symbol: "cloud.fill",
                symbolOpacity: 0.14
            )
        case "rain":
            return Palette(
                colors: [
                    Color(hex: "2088F0"),
                    Color(hex: "2898EB"),
                    Color(hex: "121214")
                ],
                glow: Color(hex: "6EC2FF"),
                symbol: "cloud.rain.fill",
                symbolOpacity: 0.15
            )
        case "snow":
            return Palette(
                colors: [
                    Color(hex: "3ED8E8"),
                    Color(hex: "38A8F8"),
                    Color(hex: "2898EB")
                ],
                glow: Color(hex: "8AD4FF"),
                symbol: "cloud.snow.fill",
                symbolOpacity: 0.16
            )
        case "fog":
            return Palette(
                colors: [
                    Color(hex: "8E8E93"),
                    Color(hex: "1E1E20")
                ],
                glow: Color(hex: "98989D"),
                symbol: "cloud.fog.fill",
                symbolOpacity: 0.14
            )
        case "thunderstorm":
            return Palette(
                colors: [
                    Color(hex: "5E63F0"),
                    Color(hex: "787DF8"),
                    Color(hex: "121214")
                ],
                glow: Color(hex: "7B80FF"),
                symbol: "cloud.bolt.rain.fill",
                symbolOpacity: 0.16
            )
        default:
            return Palette(
                colors: [
                    Color(hex: "1E1E20"),
                    Color(hex: "121214")
                ],
                glow: Color(hex: "6EC2FF"),
                symbol: "building.2.fill",
                symbolOpacity: 0.10
            )
        }
    }
}

struct WeatherHeroSection: View {
    let base: Base
    let showWeather: Bool
    let weatherCondition: String?

    @Environment(\.colorScheme) private var colorScheme

    private var cornerRadius: CGFloat { HomeMetrics.heroCornerRadius }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        heroCard
    }

    private var isDark: Bool { colorScheme == .dark }

    private var heroCard: some View {
        VStack(spacing: 0) {
            BaseHeaderView(base: base, style: .hero, fillsHero: !showWeather)

            if showWeather {
                Divider()
                    .overlay(HomeMetrics.heroDivider)

                WeatherCard(style: .hero)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            WeatherHeroBackground(condition: weatherCondition)
        }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(Color.white.opacity(isDark ? 0.10 : 0.14), lineWidth: 0.5)
        }
        .shadow(
            color: .black.opacity(isDark ? 0 : 0.38),
            radius: isDark ? 0 : 14,
            y: isDark ? 0 : 8
        )
    }
}

struct WeatherHeroBackground: View {
    let condition: String?

    private var palette: WeatherHeroTheme.Palette {
        WeatherHeroTheme.palette(for: condition)
    }

    var body: some View {
        ZStack {
            palette.gradient

            RadialGradient(
                colors: [palette.glow.opacity(0.35), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 220
            )

            RadialGradient(
                colors: [.clear, Color.black.opacity(0.28)],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 280
            )

            Image(systemName: palette.symbol)
                .font(.system(size: 148, weight: .light))
                .foregroundStyle(.white.opacity(palette.symbolOpacity))
                .offset(x: 88, y: -36)
                .accessibilityHidden(true)

            LinearGradient(
                colors: [.white.opacity(0.08), .clear, .black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [.clear, Color.black.opacity(0.24)],
                center: .center,
                startRadius: 60,
                endRadius: 300
            )
        }
    }
}
