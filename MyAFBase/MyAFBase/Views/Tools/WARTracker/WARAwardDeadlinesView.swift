import SwiftData
import SwiftUI

/// Tracks upcoming award/package suspenses and EPB/OPB-adjacent due dates.
/// Deliberately simple — a title, a date, and optional notes — since the
/// heavy lifting (reminders) happens via `WARNotificationService`.
struct WARAwardDeadlinesView: View {
    let baseID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(WARTrackerStore.self) private var store
    @State private var editingDeadline: WARAwardDeadline?
    @State private var showAdd = false

    private var deadlines: [WARAwardDeadline] {
        store.deadlines(for: baseID)
    }

    var body: some View {
        List {
            if deadlines.isEmpty {
                ContentUnavailableView(
                    "No Deadlines Yet",
                    systemImage: "flag.checkered",
                    description: Text("Add a due date for a monthly, quarterly, or annual award package.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(deadlines) { deadline in
                    Button {
                        editingDeadline = deadline
                    } label: {
                        deadlineRow(deadline)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            store.deleteDeadline(deadline)
                            syncReminders()
                        }
                    }
                }
            }
        }
        .navigationTitle("Award Deadlines")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add deadline")
            }
        }
        .sheet(isPresented: $showAdd) {
            WARAwardDeadlineEditor(baseID: baseID) { title, date, notes in
                store.addDeadline(baseID: baseID, title: title, dueDate: date, notes: notes)
                syncReminders()
            }
        }
        .sheet(item: $editingDeadline) { deadline in
            WARAwardDeadlineEditor(baseID: baseID, deadline: deadline) { title, date, notes in
                store.updateDeadline(deadline, title: title, dueDate: date, notes: notes)
                syncReminders()
            }
        }
    }

    private func deadlineRow(_ deadline: WARAwardDeadline) -> some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: "flag.checkered", tint: urgencyColor(deadline), size: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(deadline.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(deadline.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let notes = deadline.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(countdownLabel(deadline))
                .font(.caption.weight(.semibold))
                .foregroundStyle(urgencyColor(deadline))
        }
        .padding(.vertical, 4)
    }

    private func countdownLabel(_ deadline: WARAwardDeadline) -> String {
        let days = deadline.daysUntilDue
        if days < 0 { return "Past due" }
        if days == 0 { return "Today" }
        if days == 1 { return "1 day" }
        return "\(days) days"
    }

    private func urgencyColor(_ deadline: WARAwardDeadline) -> Color {
        let days = deadline.daysUntilDue
        if days < 0 { return AppTheme.danger }
        if days <= 3 { return AppTheme.warning }
        return AppTheme.accent
    }

    private func syncReminders() {
        Task {
            await WARNotificationService.rescheduleDeadlineReminders(store.allDeadlines()) { deadlineBaseID in
                if appState.currentBase?.id == deadlineBaseID {
                    return appState.currentBase?.name ?? "your base"
                }
                return deadlineBaseID
            }
        }
    }
}

private struct WARAwardDeadlineEditor: View {
    let baseID: String
    var deadline: WARAwardDeadline?
    let onSave: (String, Date, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var dueDate: Date
    @State private var notes: String

    init(baseID: String, deadline: WARAwardDeadline? = nil, onSave: @escaping (String, Date, String?) -> Void) {
        self.baseID = baseID
        self.deadline = deadline
        self.onSave = onSave
        _title = State(initialValue: deadline?.title ?? "")
        _dueDate = State(initialValue: deadline?.dueDate ?? Date())
        _notes = State(initialValue: deadline?.notes ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g. Quarterly Award)", text: $title)
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text("You'll get reminders 7, 3, and 1 day before this due date if notifications are enabled in WAR Tracker settings.")
                }
            }
            .navigationTitle(deadline == nil ? "New Deadline" : "Edit Deadline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, dueDate, notes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WARAwardDeadlinesView(baseID: "keesler")
    }
    .environment(AppState())
    .environment(WARTrackerStore(modelContext: ModelContainerFactory.preview().mainContext))
}
#endif
