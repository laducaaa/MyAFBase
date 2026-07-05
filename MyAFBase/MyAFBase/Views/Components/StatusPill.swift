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
        color = gateStatus.color
    }

    init(trafficLevel: TrafficLevel) {
        text = trafficLevel.displayName
        color = trafficLevel.color
    }
}
