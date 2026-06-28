import SwiftUI

enum LegalDisclaimerStyle {
    /// Full card with icon and secondary background — matches tool disclaimer cards.
    case standard
    /// Smaller caption-only card for footers and secondary placement.
    case compact
    /// Warning styling for PII / sensitive-data reminders.
    case warning
}

struct LegalDisclaimerCard: View {
    let text: String
    var style: LegalDisclaimerStyle = .standard
    var systemImage: String = "info.circle"

    var body: some View {
        switch style {
        case .standard:
            standardCard
        case .compact:
            compactCard
        case .warning:
            warningCard
        }
    }

    private var standardCard: some View {
        Label {
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(padding: 14, background: Color(.secondarySystemGroupedBackground))
    }

    private var compactCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 1)

            Text(text)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var warningCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#if DEBUG
#Preview("Standard") {
    LegalDisclaimerCard(text: LegalCopy.nonAffiliationShort)
        .padding()
}

#Preview("Warning") {
    LegalDisclaimerCard(text: LegalCopy.feedbackPII, style: .warning, systemImage: "exclamationmark.shield")
        .padding()
}
#endif
