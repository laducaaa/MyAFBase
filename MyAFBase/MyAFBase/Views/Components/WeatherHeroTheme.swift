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
                    Color(red: 0.98, green: 0.62, blue: 0.22),
                    Color(red: 0.55, green: 0.34, blue: 0.12),
                    Color(red: 0.18, green: 0.28, blue: 0.52)
                ],
                glow: Color(red: 1.0, green: 0.78, blue: 0.35),
                symbol: "sun.max.fill",
                symbolOpacity: 0.18
            )
        case "partly cloudy":
            return Palette(
                colors: [
                    Color(red: 0.42, green: 0.58, blue: 0.82),
                    Color(red: 0.24, green: 0.36, blue: 0.58),
                    Color(red: 0.14, green: 0.20, blue: 0.34)
                ],
                glow: Color(red: 0.72, green: 0.82, blue: 0.98),
                symbol: "cloud.sun.fill",
                symbolOpacity: 0.16
            )
        case "cloudy":
            return Palette(
                colors: [
                    Color(red: 0.45, green: 0.50, blue: 0.58),
                    Color(red: 0.28, green: 0.32, blue: 0.40),
                    Color(red: 0.16, green: 0.18, blue: 0.24)
                ],
                glow: Color(red: 0.70, green: 0.76, blue: 0.86),
                symbol: "cloud.fill",
                symbolOpacity: 0.14
            )
        case "rain":
            return Palette(
                colors: [
                    Color(red: 0.22, green: 0.38, blue: 0.58),
                    Color(red: 0.14, green: 0.26, blue: 0.44),
                    Color(red: 0.08, green: 0.14, blue: 0.24)
                ],
                glow: Color(red: 0.45, green: 0.72, blue: 0.92),
                symbol: "cloud.rain.fill",
                symbolOpacity: 0.15
            )
        case "snow":
            return Palette(
                colors: [
                    Color(red: 0.62, green: 0.74, blue: 0.88),
                    Color(red: 0.36, green: 0.48, blue: 0.66),
                    Color(red: 0.18, green: 0.26, blue: 0.40)
                ],
                glow: Color(red: 0.88, green: 0.94, blue: 1.0),
                symbol: "cloud.snow.fill",
                symbolOpacity: 0.16
            )
        case "fog":
            return Palette(
                colors: [
                    Color(red: 0.58, green: 0.60, blue: 0.64),
                    Color(red: 0.36, green: 0.38, blue: 0.42),
                    Color(red: 0.20, green: 0.22, blue: 0.26)
                ],
                glow: Color(red: 0.82, green: 0.84, blue: 0.88),
                symbol: "cloud.fog.fill",
                symbolOpacity: 0.14
            )
        case "thunderstorm":
            return Palette(
                colors: [
                    Color(red: 0.28, green: 0.24, blue: 0.48),
                    Color(red: 0.16, green: 0.14, blue: 0.32),
                    Color(red: 0.08, green: 0.08, blue: 0.16)
                ],
                glow: Color(red: 0.72, green: 0.62, blue: 0.98),
                symbol: "cloud.bolt.rain.fill",
                symbolOpacity: 0.16
            )
        default:
            return Palette(
                colors: [
                    Color(red: 0.20, green: 0.24, blue: 0.30),
                    Color(red: 0.13, green: 0.15, blue: 0.18),
                    Color(red: 0.09, green: 0.10, blue: 0.12)
                ],
                glow: Color.white.opacity(0.35),
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
    let isLoading: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var cornerRadius: CGFloat { HomeMetrics.heroCornerRadius }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var palette: WeatherHeroTheme.Palette {
        WeatherHeroTheme.palette(for: weatherCondition)
    }

    var body: some View {
        heroCard
            .background(alignment: .top) {
                ambientGlowBand
            }
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
            if showWeather && isLoading {
                HeroRefreshOverlay()
                    .clipShape(shape)
                    .transition(.opacity)
            }
        }
        .overlay {
            shape.strokeBorder(Color.white.opacity(isDark ? 0.10 : 0.14), lineWidth: 0.5)
        }
        .shadow(
            color: .black.opacity(isDark ? 0 : 0.38),
            radius: isDark ? 0 : 14,
            y: isDark ? 0 : 8
        )
    }

    /// Narrow band above the card lip — external glow only, never painted on the card face.
    private var ambientGlowBand: some View {
        RadialGradient(
            colors: [
                palette.glow.opacity(isDark ? 0.48 : 0.34),
                palette.glow.opacity(isDark ? 0.20 : 0.12),
                palette.glow.opacity(0)
            ],
            center: .bottom,
            startRadius: 4,
            endRadius: 160
        )
        .frame(height: 88)
        .frame(maxWidth: .infinity)
        .blur(radius: 28)
        .offset(y: -42)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HeroRefreshOverlay: View {
    private let sweepDuration: TimeInterval = 1.2

    @State private var sweepProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let diagonal = hypot(width, height)
            let diagonalAngle = atan2(height, width)
            let unitX = width / diagonal
            let unitY = height / diagonal
            let travel = (sweepProgress * 1.8 - 0.9) * diagonal

            ZStack {
                Color.black.opacity(0.20)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.12),
                        Color.white.opacity(0.10),
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.16),
                        .white.opacity(0.52),
                        .white.opacity(0.16),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: diagonal * 0.95, height: diagonal * 1.02)
                .rotationEffect(Angle(radians: diagonalAngle))
                .offset(x: unitX * travel, y: unitY * travel)
                .blur(radius: 1.5)
            }
        }
        .onAppear {
            sweepProgress = 0
            withAnimation(.easeInOut(duration: sweepDuration)) {
                sweepProgress = 1
            }
        }
        .allowsHitTesting(false)
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
