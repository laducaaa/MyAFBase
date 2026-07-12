import SwiftUI

struct AssignmentPhaseHeader: View {
    let base: Base
    let segment: AssignmentSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemImage: segment.systemImage, tint: segment.accentTint, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(segment.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(segment.accentTint)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    Text(segment.headline(for: base.name))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(segment.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if !base.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(base.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .elevatedCardStyle(background: Color(.secondarySystemGroupedBackground))
    }
}

extension AssignmentSegment {
    var systemImage: String {
        switch self {
        case .inbound: "airplane.arrival"
        case .stationed: "house.fill"
        case .outbound: "airplane.departure"
        }
    }

    var accentTint: Color {
        switch self {
        case .inbound: AppTheme.info
        case .stationed: AppTheme.brandPrimary
        case .outbound: AppTheme.brandSecondary
        }
    }

    var subtitle: String {
        switch self {
        case .inbound:
            "Work through your arrival checklist and in-processing guides."
        case .stationed:
            "Track personal readiness dates and plan ahead for PCS."
        case .outbound:
            "Complete out-processing and prepare for your next assignment."
        }
    }

    func headline(for baseName: String) -> String {
        switch self {
        case .inbound: "In processing at \(baseName)"
        case .stationed: "Stationed at \(baseName)"
        case .outbound: "Out processing from \(baseName)"
        }
    }
}
