import SwiftUI
import WidgetKit

struct ReadinessCountdownWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    let entry: ReadinessWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReadinessWidgetHeader(baseName: entry.baseName)

            if entry.countdowns.isEmpty {
                emptyState
                    .padding(.top, contentTopSpacing)
            } else {
                content
                    .padding(.top, contentTopSpacing)
            }

            Spacer(minLength: 0)
        }
        .padding(contentPadding)
        .containerBackground(for: .widget) {
            WidgetPalette.background(for: colorScheme)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            if let item = entry.countdowns.first {
                ReadinessCountdownSmallLayout(item: item)
            }
        case .systemMedium:
            ReadinessCountdownMediumGrid(items: Array(entry.countdowns.prefix(3)))
        case .systemLarge:
            ReadinessCountdownLargeList(items: entry.countdowns)
        default:
            if let item = entry.countdowns.first {
                ReadinessCountdownSmallLayout(item: item)
            }
        }
    }

    private var contentPadding: EdgeInsets {
        switch family {
        case .systemSmall:
            EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        case .systemMedium:
            EdgeInsets(top: 10, leading: 12, bottom: 12, trailing: 12)
        case .systemLarge:
            EdgeInsets(top: 12, leading: 14, bottom: 14, trailing: 14)
        default:
            EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        }
    }

    private var contentTopSpacing: CGFloat {
        switch family {
        case .systemSmall: 10
        case .systemMedium: 8
        case .systemLarge: 10
        default: 8
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No dates set")
                .font(.headline)
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
            Text("Add readiness dates in Assignment.")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
        }
    }
}

// MARK: - Header

private struct ReadinessWidgetHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let baseName: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "calendar.badge.clock")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))

            Text(baseName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Small (2×2)

private struct ReadinessCountdownSmallLayout: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: ReadinessWidgetItemSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: item.systemImage)
                    .font(.title2)
                    .foregroundStyle(WidgetPalette.statusColor(for: item.statusRaw, colorScheme: colorScheme))
                    .frame(width: 30)

                countdownBlock
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .lineLimit(1)

                Text(item.detailLabel)
                    .font(.caption)
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    @ViewBuilder
    private var countdownBlock: some View {
        if let value = item.countdownValue {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.statusColor(for: item.statusRaw, colorScheme: colorScheme))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                Text(item.countdownLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Text(item.countdownLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(2)
        }
    }
}

// MARK: - Medium (2×4) — 3-column grid

private struct ReadinessCountdownMediumGrid: View {
    let items: [ReadinessWidgetItemSnapshot]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 1)
                        .padding(.vertical, 2)
                }

                ReadinessCountdownGridCell(item: item)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ReadinessCountdownGridCell: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: ReadinessWidgetItemSnapshot

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(WidgetPalette.statusColor(for: item.statusRaw, colorScheme: colorScheme))

            if let value = item.countdownValue {
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.statusColor(for: item.statusRaw, colorScheme: colorScheme))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(item.countdownLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            } else {
                Text(item.countdownLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            VStack(spacing: 1) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(item.detailLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Large (4×4)

private struct ReadinessCountdownLargeList: View {
    let items: [ReadinessWidgetItemSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(items) { item in
                ReadinessCountdownListRow(item: item)
            }
        }
    }
}

private struct ReadinessCountdownListRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: ReadinessWidgetItemSnapshot

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.statusColor(for: item.statusRaw, colorScheme: colorScheme))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .lineLimit(1)

                Text(item.detailLabel)
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let value = item.countdownValue {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(value)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(WidgetPalette.statusColor(for: item.statusRaw, colorScheme: colorScheme))
                    Text(item.countdownLabel)
                        .font(.caption2)
                        .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            } else {
                Text(item.countdownLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
            }
        }
    }
}
