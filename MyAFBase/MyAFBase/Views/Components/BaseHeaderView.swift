import SwiftUI

enum BaseHeaderStyle {
    case standard
    case hero
}

struct BaseHeaderView: View {
    let base: Base
    var style: BaseHeaderStyle = .standard
    var fillsHero: Bool = false

    var body: some View {
        Group {
            if style == .standard {
                headerContent
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                headerContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(base.name), \(base.location), \(base.wing)")
    }

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: style == .hero ? 6 : 4) {
            Text(base.name)
                .font(style == .hero ? .title2.weight(.bold) : .title2.bold())
                .foregroundStyle(style == .hero ? .white : .primary)

            Text("\(base.location) · \(base.wing)")
                .font(.subheadline)
                .foregroundStyle(style == .hero ? HomeMetrics.heroSecondaryText : .secondary)

            if base.fullName != base.name {
                Text(base.fullName)
                    .font(.caption)
                    .foregroundStyle(style == .hero ? HomeMetrics.heroSecondaryText.opacity(0.85) : Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(heroPadding)
    }

    private var heroPadding: EdgeInsets {
        guard style == .hero else { return EdgeInsets() }
        return EdgeInsets(
            top: 20,
            leading: 20,
            bottom: fillsHero ? 24 : 16,
            trailing: 20
        )
    }
}
