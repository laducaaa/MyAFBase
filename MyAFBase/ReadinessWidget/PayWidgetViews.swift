import SwiftUI
import WidgetKit

struct PayWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    let entry: PayWidgetEntry

    private var snapshot: PayWidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(systemImage: "dollarsign.circle.fill", title: "Pay Calendar")

            if !snapshot.isAvailable {
                emptyContent
                    .padding(.top, 10)
            } else {
                switch family {
                case .systemMedium:
                    mediumContent
                        .padding(.top, 8)
                default:
                    smallContent
                        .padding(.top, 10)
                }
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

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: snapshot.symbolName)
                    .font(.title2)
                    .foregroundStyle(WidgetPalette.payAccent(for: colorScheme))

                Text("\(snapshot.daysUntil)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(snapshot.daysUntil == 1 ? "day" : "days")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
            }

            Text(snapshot.nextTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                .lineLimit(2)

            Text(snapshot.nextDateLabel)
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
        }
    }

    private var mediumContent: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Next pay")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: snapshot.symbolName)
                        .font(.title3)
                        .foregroundStyle(WidgetPalette.payAccent(for: colorScheme))

                    Text("\(snapshot.daysUntil)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))

                    Text(snapshot.daysUntil == 1 ? "day" : "days")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                }

                Text(snapshot.nextTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .lineLimit(2)

                Text(snapshot.nextDateLabel)
                    .font(.caption)
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if snapshot.upcoming.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))

                    ForEach(Array(snapshot.upcoming.dropFirst().prefix(2).enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 6) {
                            Image(systemName: item.symbolName)
                                .font(.caption2)
                                .foregroundStyle(WidgetPalette.payAccent(for: colorScheme))
                                .frame(width: 14)

                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                                    .lineLimit(1)
                                Text(item.shortDateLabel)
                                    .font(.caption2)
                                    .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "dollarsign.circle")
                .font(.title2)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))

            Text("Open MyAFBase")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))

            Text("Pay dates refresh when you open the app.")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(2)
        }
    }
}
