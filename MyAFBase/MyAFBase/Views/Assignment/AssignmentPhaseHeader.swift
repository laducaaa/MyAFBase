import SwiftUI

struct AssignmentPhaseHeader: View {
    let base: Base
    let segment: AssignmentSegment

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
                colors: segment.gradientColors,
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
            "Track readiness dates and go-to AFIs."
        case .outbound:
            "Complete out-processing and prepare for your next assignment."
        }
    }

    func headline(for baseName: String) -> String {
        switch self {
        case .inbound: "Arriving at \(baseName)"
        case .stationed: "Stationed at \(baseName)"
        case .outbound: "Leaving \(baseName)"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .inbound:
            [Color(red: 0.12, green: 0.28, blue: 0.48), Color(red: 0.18, green: 0.38, blue: 0.58)]
        case .stationed:
            [Color(red: 0.14, green: 0.32, blue: 0.28), Color(red: 0.20, green: 0.42, blue: 0.36)]
        case .outbound:
            [Color(red: 0.36, green: 0.24, blue: 0.18), Color(red: 0.48, green: 0.32, blue: 0.24)]
        }
    }
}
