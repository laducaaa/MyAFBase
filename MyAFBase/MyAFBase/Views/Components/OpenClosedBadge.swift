import SwiftUI

struct OpenClosedBadge: View {
    let status: OpenStatus

    var body: some View {
        StatusPill(text: ResourceHoursStatus.label(for: status), color: color)
    }

    private var color: Color {
        switch status {
        case .open, .alwaysOpen: .green
        case .closed: .secondary
        }
    }
}
