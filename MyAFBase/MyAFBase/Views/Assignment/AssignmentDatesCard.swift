import SwiftUI

struct AssignmentDatesCard: View {
    let baseID: String
    let segment: AssignmentSegment

    @Environment(AssignmentProfileStore.self) private var assignmentProfileStore

    private var profile: AssignmentProfile {
        assignmentProfileStore.profile(for: baseID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Key dates", systemImage: "calendar")
                .font(.headline)

            Text(helperText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            switch segment {
            case .inbound:
                dateRow(
                    title: "Report date",
                    date: profile.reportDate,
                    placeholder: "When you in-process"
                ) { newDate in
                    assignmentProfileStore.updateReportDate(newDate, baseID: baseID)
                }

            case .outbound:
                dateRow(
                    title: "PCS date",
                    date: profile.pcsDate,
                    placeholder: "When you depart"
                ) { newDate in
                    assignmentProfileStore.updatePCSDate(newDate, baseID: baseID)
                }

            case .stationed:
                dateRow(
                    title: "Report date",
                    date: profile.reportDate,
                    placeholder: "Optional"
                ) { newDate in
                    assignmentProfileStore.updateReportDate(newDate, baseID: baseID)
                }

                Divider()

                dateRow(
                    title: "PCS date",
                    date: profile.pcsDate,
                    placeholder: "Optional"
                ) { newDate in
                    assignmentProfileStore.updatePCSDate(newDate, baseID: baseID)
                }
            }
        }
        .padding(AssignmentMetrics.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AssignmentMetrics.cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(AssignmentMetrics.cardShadowOpacity), radius: 6, y: 2)
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

    private func dateRow(
        title: String,
        date: Date?,
        placeholder: String,
        onChange: @escaping (Date?) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Spacer()

                if date != nil {
                    Button("Clear", role: .destructive) {
                        onChange(nil)
                    }
                    .font(.caption)
                }
            }

            DatePicker(
                title,
                selection: Binding(
                    get: { date ?? Date() },
                    set: { onChange($0) }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)

            if date == nil {
                Text(placeholder)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if let date, let countdown = countdownText(title: title, date: date) {
                Text(countdown)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private func countdownText(title: String, date: Date) -> String? {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        let subject = title.localizedCaseInsensitiveContains("PCS") ? "PCS" : "Report"

        switch days {
        case ..<0: return "\(subject) date has passed"
        case 0: return "\(subject) is today"
        case 1: return "1 day until \(subject.lowercased())"
        default: return "\(days) days until \(subject.lowercased())"
        }
    }
}
