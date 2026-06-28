import SwiftUI

struct CompactResourceHoursView: View {
    let hours: String
    var maxLines: Int = 4

    private var display: HoursCardDisplay {
        HoursParser.cardDisplay(for: hours, maxLines: maxLines)
    }

    var body: some View {
        HStack(alignment: .top, spacing: ExploreMetrics.cardRowSpacing) {
            Image(systemName: "clock")
                .font(ExploreMetrics.cardRowIconFont)
                .frame(width: ExploreMetrics.cardRowIconWidth, alignment: .center)
                .foregroundStyle(.secondary)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                if display.lines.isEmpty {
                    Text(hours)
                        .font(ExploreMetrics.cardRowFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    ForEach(display.lines) { line in
                        hoursLine(line)
                    }

                    if display.hasMore {
                        Text("Tap for full hours")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func hoursLine(_ line: HoursCardLine) -> some View {
        if line.label.isEmpty {
            Text(line.value)
                .font(ExploreMetrics.cardRowFont)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(line.label)
                    .font(ExploreMetrics.cardRowFont)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 72, alignment: .leading)

                Text(line.value)
                    .font(ExploreMetrics.cardRowFont)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
