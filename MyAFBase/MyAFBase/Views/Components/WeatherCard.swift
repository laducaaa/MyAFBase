import SwiftUI

enum WeatherCardStyle {
    case standard
    case hero
}

struct WeatherCard: View {
    @Environment(AppState.self) private var appState
    var style: WeatherCardStyle = .standard

    private let cacheTTL: TimeInterval = 15 * 60

    private var activeWeather: Weather? {
        appState.displayWeather
    }

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardCard
            case .hero:
                heroCard
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var standardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                Text("Weather")
                    .font(.headline)
                Spacer()
                if appState.isWeatherLoading {
                    ProgressView()
                        .accessibilityLabel("Loading weather")
                }
            }

            weatherBody
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Conditions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HomeMetrics.heroSecondaryText)

                    if let location = appState.currentBase?.location {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(HomeMetrics.heroSecondaryText.opacity(0.85))
                    }
                }

                Spacer()

                refreshButton
            }

            weatherBody

            if !appState.isWeatherLoading, let weather = activeWeather, !weather.isPlaceholder {
                heroMetadata(for: weather)
            }
        }
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 20, trailing: 20))
    }

    @ViewBuilder
    private var weatherBody: some View {
        if appState.isWeatherLoading {
            weatherSkeleton
        } else if let weather = activeWeather {
            switch style {
            case .standard:
                standardWeatherContent(weather)
            case .hero:
                heroWeatherContent(weather)
            }
        } else {
            Text("Weather unavailable")
                .foregroundStyle(style == .hero ? HomeMetrics.heroSecondaryText : .secondary)
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await appState.refreshWeather(force: true) }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(appState.isWeatherLoading)
        .opacity(appState.isWeatherLoading ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.2), value: appState.isWeatherLoading)
        .accessibilityLabel(appState.isWeatherLoading ? "Refreshing weather" : "Refresh weather")
    }

    private var weatherSkeleton: some View {
        Group {
            if style == .hero {
                heroWeatherSkeleton
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    skeletonBar(width: 120, height: 44, opacity: 0.08)
                    skeletonBar(width: 120, height: 16, opacity: 0.08)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityLabel("Loading weather")
    }

    private var heroWeatherSkeleton: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                skeletonBar(width: 148, height: 56, opacity: 0.18)
                skeletonBar(width: 110, height: 14, opacity: 0.12)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    if index > 0 { Spacer() }
                    VStack(spacing: 8) {
                        skeletonBar(width: 28, height: 22, opacity: 0.14)
                        skeletonBar(width: 54, height: 12, opacity: 0.12)
                        skeletonBar(width: 40, height: 10, opacity: 0.10)
                    }
                    .frame(minWidth: 72)
                }
            }
        }
        .redacted(reason: .placeholder)
    }

    private func skeletonBar(width: CGFloat, height: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(style == .hero ? Color.white.opacity(opacity) : Color.primary.opacity(opacity))
            .frame(width: width, height: height)
    }

    @ViewBuilder
    private func standardWeatherContent(_ weather: Weather) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                temperatureText(weather, fontSize: 36)
                Text(weather.conditionName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let feelsLike = weather.feelsLikeDisplayF {
                    Text("Feels like \(feelsLike)°F")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Label("\(Int(weather.windMph.rounded())) mph", systemImage: "wind")
                    .font(.caption)
                Label("\(weather.humidity)%", systemImage: "humidity")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }

        weatherTimestamp(weather)
    }

    @ViewBuilder
    private func heroWeatherContent(_ weather: Weather) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                temperatureText(weather, fontSize: 64)

                if let feelsLike = weather.feelsLikeDisplayF {
                    Text("Feels like \(feelsLike)°F")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HomeMetrics.heroSecondaryText)
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                heroMetric(
                    icon: "wind",
                    value: weather.isPlaceholder ? "--" : "\(Int(weather.windMph.rounded())) mph",
                    label: "Wind"
                )

                Spacer()

                heroConditionMetric(weather)

                Spacer()

                heroMetric(
                    icon: "humidity.fill",
                    value: weather.isPlaceholder ? "--" : "\(weather.humidity)%",
                    label: "Humidity"
                )
            }
        }
    }

    private func heroMetric(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(HomeMetrics.heroSecondaryText)
        }
        .frame(minWidth: 72)
    }

    private func heroConditionMetric(_ weather: Weather) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: weather.condition.symbolName)
                    .font(.title3)
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(conditionColor(for: weather.condition))
                Text(weather.conditionName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            Text("Condition")
                .font(.caption)
                .foregroundStyle(HomeMetrics.heroSecondaryText)
        }
        .frame(minWidth: 96)
    }

    @ViewBuilder
    private func temperatureText(_ weather: Weather, fontSize: CGFloat) -> some View {
        if weather.isPlaceholder {
            Text("--°F")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(style == .hero ? .white : .primary)
        } else {
            Text("\(Int(weather.tempF.rounded()))°F")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(style == .hero ? .white : .primary)
        }
    }

    @ViewBuilder
    private func heroMetadata(for weather: Weather) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isCached(weather) ? "clock.arrow.circlepath" : "location.fill")
                .font(.caption2)
            if isCached(weather) {
                Text("Cached · \(timestampText(for: weather))")
            } else {
                Text("Observed \(timestampText(for: weather))")
            }
        }
        .font(.caption2)
        .foregroundStyle(isCached(weather) ? AppTheme.warning.opacity(0.9) : HomeMetrics.heroSecondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(metadataAccessibilityLabel(for: weather))
    }

    @ViewBuilder
    private func weatherTimestamp(_ weather: Weather) -> some View {
        if isCached(weather) {
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                Text("Cached · \(timestampText(for: weather))")
                    .font(.caption2)
            }
            .foregroundStyle(AppTheme.warning)
            .accessibilityLabel("Showing cached weather from \(fullTimestampText(for: weather))")
        } else {
            Text("Observed \(timestampText(for: weather))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func isCached(_ weather: Weather) -> Bool {
        Date().timeIntervalSince(weather.lastUpdated) >= cacheTTL && !weather.isPlaceholder
    }

    private func timestampText(for weather: Weather) -> String {
        let date = weather.observationTime ?? weather.lastUpdated
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func fullTimestampText(for weather: Weather) -> String {
        let date = weather.observationTime ?? weather.lastUpdated
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func metadataAccessibilityLabel(for weather: Weather) -> String {
        if isCached(weather) {
            return "Showing cached weather observed \(fullTimestampText(for: weather))"
        }
        return "Weather observed \(fullTimestampText(for: weather)) at this installation"
    }

    private func conditionColor(for condition: WeatherCondition) -> Color {
        switch condition {
        case .clear, .mainlyClear: return .yellow
        case .partlyCloudy: return .white.opacity(0.95)
        case .rain, .freezingRain, .rainShowers, .drizzle, .freezingDrizzle: return .cyan
        case .snow, .snowShowers: return .white
        case .thunderstorm: return .yellow
        default: return .white.opacity(0.9)
        }
    }
}
