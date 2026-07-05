import SwiftUI

struct MenuAssignmentPhaseRow: View {
    let baseID: String

    @Environment(AssignmentProfileStore.self) private var assignmentProfileStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Assignment phase")
                .font(.subheadline.weight(.semibold))

            Text("Controls what you see in My Assignment.")
                .font(.caption)
                .foregroundStyle(.secondary)

            AssignmentPhaseToggle(selection: phaseBinding)
        }
        .accessibilityElement(children: .contain)
    }

    private var phaseBinding: Binding<AssignmentSegment> {
        Binding(
            get: { assignmentProfileStore.phase(for: baseID) },
            set: { assignmentProfileStore.updatePhase($0, baseID: baseID) }
        )
    }
}
