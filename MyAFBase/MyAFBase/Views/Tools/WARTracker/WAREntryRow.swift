import SwiftUI

struct WAREntryRow: View {
    let entry: WAREntry
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemImage: entry.category.systemImage, tint: entry.category.tint, size: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !metaChips.isEmpty {
                        WARFlowChips(items: metaChips)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(WARPressableButtonStyle(scale: 0.985))
    }

    private var metaChips: [String] {
        var chips: [String] = [entry.category.title]
        if let factor = entry.performanceFactor {
            chips.append(factor.title)
        }
        chips.append(contentsOf: entry.tags.map { "#\($0)" })
        if let hours = entry.hours, hours > 0 {
            chips.append(hours == hours.rounded() ? "\(Int(hours))h" : String(format: "%.1fh", hours))
        }
        return chips
    }
}

private struct WARFlowChips: View {
    let items: [String]

    var body: some View {
        AFISearchChipLayout(spacing: 5) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
        }
    }
}
