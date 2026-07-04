import SwiftUI

struct AssignmentPhaseHeader: View {
    let base: Base
    let segment: AssignmentSegment

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: segment.systemImage)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 4) {
                    Text(segment.headline(for: base.name))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(segment.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(base.description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: AppTheme.phaseGradientColors(for: segment, colorScheme: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AssignmentMetrics.cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(AppTheme.cardShadowOpacity), radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
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
