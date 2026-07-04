import SwiftUI

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel(text)
    }
}

extension StatusPill {
    init(gateStatus: GateStatus) {
        text = gateStatus.displayName
        color = Self.color(for: gateStatus)
    }

    init(trafficLevel: TrafficLevel) {
        text = trafficLevel.displayName
        color = Self.color(for: trafficLevel)
    }

    private static func color(for status: GateStatus) -> Color {
        switch status {
        case .open: return AppTheme.success
        case .closed: return AppTheme.danger
        case .delayed: return AppTheme.warning
        case .unknown: return AppTheme.muted
        }
    }

    private static func color(for traffic: TrafficLevel) -> Color {
        switch traffic {
        case .none: return AppTheme.muted
        case .low: return AppTheme.success
        case .moderate: return AppTheme.warning
        case .high: return AppTheme.danger
        case .unknown: return AppTheme.muted
        }
    }
}
