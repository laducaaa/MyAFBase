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
        case .open: return .green
        case .closed: return .red
        case .delayed: return .orange
        case .unknown: return .gray
        }
    }

    private static func color(for traffic: TrafficLevel) -> Color {
        switch traffic {
        case .none: return .gray
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        case .unknown: return .gray
        }
    }
}
