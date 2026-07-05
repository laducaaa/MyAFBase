import SwiftUI
import SwiftData

struct PCSChecklistCard: View {
    let baseID: String
    let kind: PCSChecklistKind

    @Environment(\.modelContext) private var modelContext
    @Query private var completions: [ChecklistCompletion]
    @State private var showResetAlert = false

    private var items: [PCSChecklistItem] {
        PCSChecklist.items(for: kind)
    }

    private var completedIDs: Set<String> {
        Set(completions.map(\.itemID))
    }

    private var completedCount: Int {
        items.filter { completedIDs.contains($0.id) }.count
    }

    private var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedCount) / Double(items.count)
    }

    init(baseID: String, kind: PCSChecklistKind) {
        self.baseID = baseID
        self.kind = kind

        let id = baseID
        let kindValue = kind.rawValue
        _completions = Query(
            filter: #Predicate<ChecklistCompletion> {
                $0.baseID == id && $0.kind == kindValue
            },
            sort: [SortDescriptor(\.completedAt)]
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 36)
                    }

                    Toggle(isOn: binding(for: item)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.body)
                                .foregroundStyle(.primary)

                            if let detail = item.detail {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .toggleStyle(ChecklistToggleStyle())
                }
            }

            footer
        }
        .appCardStyle(padding: AssignmentMetrics.cardPadding)
        .alert("Reset Checklist?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetChecklist()
            }
        } message: {
            Text("This will uncheck all items on your \(kind.title.lowercased()).")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline)

                Spacer()

                Text("\(completedCount)/\(items.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(progress >= 1 ? AppTheme.success : .secondary)
            }

            ProgressView(value: progress)
                .tint(progress >= 1 ? AppTheme.success : AppTheme.accent)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kind.footer)
                .font(.caption)
                .foregroundStyle(.secondary)

            if completedCount > 0 {
                Button("Reset Checklist", role: .destructive) {
                    showResetAlert = true
                }
                .font(.caption)
            }
        }
    }

    private func binding(for item: PCSChecklistItem) -> Binding<Bool> {
        Binding(
            get: { completedIDs.contains(item.id) },
            set: { isCompleted in
                if isCompleted {
                    guard !completedIDs.contains(item.id) else { return }
                    modelContext.insert(
                        ChecklistCompletion(baseID: baseID, itemID: item.id, kind: kind.rawValue)
                    )
                } else if let existing = completions.first(where: { $0.itemID == item.id }) {
                    modelContext.delete(existing)
                }
                try? modelContext.save()
            }
        )
    }

    private func resetChecklist() {
        for completion in completions {
            modelContext.delete(completion)
        }
        try? modelContext.save()
    }
}

private struct ChecklistToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(configuration.isOn ? AppTheme.success : Color(.tertiaryLabel))
                    .frame(width: 24)

                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
