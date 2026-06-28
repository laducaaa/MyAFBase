import SwiftUI
import WidgetKit

struct OpenNowWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    let entry: OpenNowWidgetEntry

    private var snapshot: OpenNowWidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(systemImage: "clock.badge.checkmark.fill", title: snapshot.baseName)

            content
                .padding(.top, contentTopSpacing)

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
            smallContent
        case .systemMedium:
            mediumContent
        case .systemLarge:
            largeContent
        default:
            smallContent
        }
    }

    @ViewBuilder
    private var smallContent: some View {
        if let item = entry.selectedBookmark {
            OpenNowBookmarkDetail(item: item)
        } else {
            bookmarkEmptyState
        }
    }

    private var mediumContent: some View {
        let items = Array(snapshot.items.prefix(3))

        return Group {
            if items.isEmpty {
                openNowEmptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(snapshot.summaryText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.openNowAccent(for: colorScheme))

                    OpenNowMediumGrid(items: items)
                }
            }
        }
    }

    private var largeContent: some View {
        let items = Array(snapshot.items.prefix(8))

        return Group {
            if items.isEmpty {
                openNowEmptyState
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(snapshot.summaryText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.openNowAccent(for: colorScheme))

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(items) { item in
                            OpenNowWidgetRow(item: item)
                        }
                    }
                }
            }
        }
    }

    private var bookmarkEmptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No bookmark selected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))

            Text("Edit widget to pick a saved gate or resource.")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(2)
        }
    }

    private var openNowEmptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nothing open right now")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))

            Text("Check Explore for hours and gate status.")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(2)
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
}

// MARK: - Small bookmark detail

private struct OpenNowBookmarkDetail: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: OpenNowWidgetItemSnapshot

    private var statusColor: Color {
        item.isOpen
            ? WidgetPalette.openNowAccent(for: colorScheme)
            : WidgetPalette.statusColor(for: "overdue", colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.statusLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(statusColor)

                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            }

            HStack(spacing: 4) {
                Text(item.categoryLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))

                if let detail = item.detail {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            }
        }
    }
}

// MARK: - Medium 3-column grid

private struct OpenNowMediumGrid: View {
    let items: [OpenNowWidgetItemSnapshot]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 1)
                        .padding(.vertical, 2)
                }

                OpenNowGridCell(item: item)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct OpenNowGridCell: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: OpenNowWidgetItemSnapshot

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(WidgetPalette.openNowAccent(for: colorScheme))

            Text(item.categoryLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.openNowAccent(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(1)

            Text(item.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.75)

            if let detail = item.detail {
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Large list row

private struct OpenNowWidgetRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: OpenNowWidgetItemSnapshot

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.openNowAccent(for: colorScheme))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 4) {
                    Text(item.categoryLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))

                    if let detail = item.detail {
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(WidgetPalette.tertiaryText(for: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}
