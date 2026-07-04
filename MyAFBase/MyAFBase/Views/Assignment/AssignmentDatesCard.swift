import SwiftUI

private enum AssignmentKeyDateField: String, Identifiable {
    case report
    case pcs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .report: "Report date"
        case .pcs: "PCS date"
        }
    }

    var systemImage: String {
        switch self {
        case .report: "airplane.arrival"
        case .pcs: "airplane.departure"
        }
    }

    var emptyPrompt: String {
        switch self {
        case .report: "When you in-processed or arrived"
        case .pcs: "When you plan to depart"
        }
    }

    var countdownSubject: String {
        switch self {
        case .report: "Report"
        case .pcs: "PCS"
        }
    }
}

struct AssignmentDatesCard: View {
    let baseID: String
    let segment: AssignmentSegment

    @Environment(AssignmentProfileStore.self) private var assignmentProfileStore
    @State private var editingField: AssignmentKeyDateField?
    @State private var draftDate = Date()

    private var profile: AssignmentProfile {
        assignmentProfileStore.profile(for: baseID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Key dates")
                    .font(.headline)

                Text(helperText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AssignmentMetrics.cardPadding)
            .padding(.top, AssignmentMetrics.cardPadding)

            VStack(spacing: 0) {
                switch segment {
                case .inbound:
                    keyDateRow(
                        field: .report,
                        date: profile.reportDate,
                        emptyPrompt: "When you in-process"
                    )

                case .outbound:
                    keyDateRow(
                        field: .pcs,
                        date: profile.pcsDate,
                        emptyPrompt: "When you depart"
                    )

                case .stationed:
                    keyDateRow(
                        field: .report,
                        date: profile.reportDate,
                        emptyPrompt: "Optional"
                    )

                    Divider()
                        .padding(.leading, 56)

                    keyDateRow(
                        field: .pcs,
                        date: profile.pcsDate,
                        emptyPrompt: "Optional — powers PCS countdown"
                    )
                }
            }
            .padding(.bottom, 4)
        }
        .appCardStyle(padding: 0)
        .sheet(item: $editingField) { field in
            keyDateEditor(for: field)
        }
    }

    private var helperText: String {
        switch segment {
        case .inbound:
            "Your report date helps countdowns and checklists stay relevant."
        case .stationed:
            "Optional dates power Home countdowns when you start planning your PCS."
        case .outbound:
            "Your PCS date feeds the Leave Planner and outbound checklist pacing."
        }
    }

    private func keyDateRow(
        field: AssignmentKeyDateField,
        date: Date?,
        emptyPrompt: String
    ) -> some View {
        Button {
            editingField = field
            draftDate = date ?? Date()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: field.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(field.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let countdown = countdownText(subject: field.countdownSubject, date: date) {
                            Text(countdown)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(countdownColor(for: date))
                        }
                    } else {
                        Text(emptyPrompt)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 8)

                if date != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Set")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.accent.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, AssignmentMetrics.cardPadding)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(field.title), \(date?.formatted(date: .abbreviated, time: .omitted) ?? emptyPrompt)")
    }

    private func keyDateEditor(for field: AssignmentKeyDateField) -> some View {
        let currentDate = field == .report ? profile.reportDate : profile.pcsDate

        return NavigationStack {
            Form {
                Section {
                    DatePicker(
                        field.title,
                        selection: $draftDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                } footer: {
                    Text(editorFooter(for: field))
                }
            }
            .navigationTitle(field.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingField = nil }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDate(draftDate, for: field)
                        editingField = nil
                    }
                    .fontWeight(.semibold)
                }

                if currentDate != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            saveDate(nil, for: field)
                            editingField = nil
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func editorFooter(for field: AssignmentKeyDateField) -> String {
        switch (segment, field) {
        case (.inbound, .report):
            "Used for in-processing countdowns on Home and Assignment."
        case (.outbound, .pcs):
            "Feeds Leave Planner pacing and outbound checklist reminders."
        case (.stationed, .report):
            "Optional reference for how long you've been at this assignment."
        case (.stationed, .pcs):
            "Shows a PCS countdown on Home when within four months."
        default:
            field.emptyPrompt
        }
    }

    private func saveDate(_ date: Date?, for field: AssignmentKeyDateField) {
        switch field {
        case .report:
            assignmentProfileStore.updateReportDate(date, baseID: baseID)
        case .pcs:
            assignmentProfileStore.updatePCSDate(date, baseID: baseID)
        }
    }

    private func countdownText(subject: String, date: Date) -> String? {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        switch days {
        case ..<0: return "\(subject) date has passed"
        case 0: return "\(subject) is today"
        case 1: return "1 day until \(subject.lowercased())"
        default: return "\(days) days until \(subject.lowercased())"
        }
    }

    private func countdownColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        if days < 0 { return .secondary }
        if days <= 30 { return AppTheme.warning }
        return AppTheme.accent
    }
}
