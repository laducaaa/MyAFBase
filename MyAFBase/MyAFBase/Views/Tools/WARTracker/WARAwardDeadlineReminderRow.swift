import SwiftUI

/// Card-style row for a WAR award deadline, matching the Reminders tab look.
struct WARAwardDeadlineReminderRow: View {
    let deadline: WARAwardDeadline

    private var status: ReadinessStatus {
        let days = deadline.daysUntilDue
        if days < 0 { return .overdue }
        if days <= 7 { return .dueSoon }
        return .onTrack
    }

    private var countdownValue: Int {
        max(abs(deadline.daysUntilDue), 0)
    }

    private var countdownUnit: String {
        let days = deadline.daysUntilDue
        if days < 0 { return days == -1 ? "day late" : "days late" }
        if days == 0 { return "today" }
        if days == 1 { return "day" }
        return "days"
    }

    private var subtitle: String {
        let days = deadline.daysUntilDue
        if days < 0 { return "Past due" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days) days"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            IconBadge(systemImage: "flag.checkered", tint: status.color, size: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(deadline.title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.12), in: Capsule())

                Text(deadline.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(countdownValue)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(status.color)

                Text(countdownUnit)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .frame(minWidth: 44)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .elevatedCardStyle(background: Color(.secondarySystemGroupedBackground))
    }
}

#if DEBUG
#Preview {
    WARAwardDeadlineReminderRow(
        deadline: WARAwardDeadline(baseID: "keesler", title: "Quarterly Award", dueDate: .now)
    )
    .padding()
}
#endif
