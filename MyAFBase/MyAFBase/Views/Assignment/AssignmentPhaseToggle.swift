import SwiftUI

struct AssignmentPhaseToggle: View {
    @Binding var selection: AssignmentSegment

    var body: some View {
        GlassSegmentToggle(
            options: Array(AssignmentSegment.allCases),
            selection: $selection,
            label: \.title,
            layout: .equalWidth
        )
    }
}
