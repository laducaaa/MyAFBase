import SwiftUI

struct BasePickerRow: View {
    let base: BaseIndexEntry
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                IconBadge(
                    systemImage: base.region.pickerIcon,
                    tint: base.region.pickerAccent,
                    size: 44
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(base.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Label(base.location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)

                    Text("\(base.wing) · \(base.region.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                selectionIndicator
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .basePickerRowStyle(isSelected: isSelected)
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(BasePickerPressStyle())
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .symbolEffect(.bounce, value: isSelected)
        } else {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private var accessibilityText: String {
        if isSelected {
            return "\(base.name), \(base.location), \(base.wing), \(base.region.displayName), currently selected"
        }
        return "\(base.name), \(base.location), \(base.wing), \(base.region.displayName)"
    }
}
