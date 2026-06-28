import SwiftUI

struct BasePickerRow: View {
    let base: BaseIndexEntry
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                baseIcon

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(base.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        Spacer(minLength: 0)

                        regionBadge
                    }

                    Label(base.location, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)

                    Text(base.wing)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }

                selectionIndicator
            }
            .padding(14)
            .basePickerCardStyle(isSelected: isSelected)
            .contentShape(RoundedRectangle(cornerRadius: BasePickerMetrics.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(BasePickerPressStyle())
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var baseIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            base.region.pickerAccent.opacity(0.22),
                            base.region.pickerAccent.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: base.region.pickerIcon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(base.region.pickerAccent)
        }
        .frame(width: BasePickerMetrics.iconSize, height: BasePickerMetrics.iconSize)
    }

    private var regionBadge: some View {
        Text(base.region.displayName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(base.region.pickerAccent)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(base.region.pickerAccent.opacity(0.12), in: Capsule())
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.primary)
                .symbolEffect(.bounce, value: isSelected)
        } else {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 20)
        }
    }

    private var accessibilityText: String {
        if isSelected {
            return "\(base.name), \(base.location), \(base.wing), \(base.region.displayName), currently selected"
        }
        return "\(base.name), \(base.location), \(base.wing), \(base.region.displayName)"
    }
}
