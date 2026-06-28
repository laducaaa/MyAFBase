import SwiftUI
import WidgetKit

struct WeatherWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    let entry: WeatherWidgetEntry

    private var snapshot: WeatherWidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(systemImage: "cloud.sun.fill", title: snapshot.baseName)

            if snapshot.isAvailable {
                availableContent
                    .padding(.top, family == .systemSmall ? 10 : 8)
            } else {
                unavailableContent
                    .padding(.top, 10)
            }

            Spacer(minLength: 0)
        }
        .padding(family == .systemSmall
            ? EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            : EdgeInsets(top: 10, leading: 12, bottom: 12, trailing: 12))
        .containerBackground(for: .widget) {
            WidgetPalette.background(for: colorScheme)
        }
    }

    @ViewBuilder
    private var availableContent: some View {
        switch family {
        case .systemMedium:
            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: snapshot.symbolName)
                        .font(.system(size: 34))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(WidgetPalette.weatherAccent(for: colorScheme))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.tempDisplay)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Text(snapshot.conditionName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    if let feelsLike = snapshot.feelsLikeDisplay {
                        metadataLine(feelsLike)
                    }
                    if let wind = snapshot.windMph {
                        metadataLine("Wind \(wind) mph")
                    }
                    if let humidity = snapshot.humidity {
                        metadataLine("Humidity \(humidity)%")
                    }
                    if let location = snapshot.location {
                        Text(location)
                            .font(.caption2)
                            .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: snapshot.symbolName)
                        .font(.title)
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(WidgetPalette.weatherAccent(for: colorScheme))

                    Text(snapshot.tempDisplay)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                Text(snapshot.conditionName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .lineLimit(1)

                if let feelsLike = snapshot.feelsLikeDisplay {
                    Text(feelsLike)
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                } else if let wind = snapshot.windMph {
                    Text("Wind \(wind) mph")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                }
            }
        }
    }

    private var unavailableContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: snapshot.symbolName)
                .font(.title2)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))

            Text(snapshot.conditionName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))

            Text("Open MyAFBase to refresh weather.")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(2)
        }
    }

    private func metadataLine(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
            .lineLimit(1)
    }
}
