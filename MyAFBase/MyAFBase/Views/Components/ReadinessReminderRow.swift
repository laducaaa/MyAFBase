import SwiftUI

struct ReadinessReminderRow: View {
    enum Style {
        case plain
        case card
    }

    let reminder: ReadinessReminder
    var style: Style = .card
    var onDismiss: (() -> Void)?

    var body: some View {
        Group {
            switch style {
            case .plain:
                rowContent
                    .padding(.vertical, 4)
            case .card:
                rowContent
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .elevatedCardStyle(background: Color(.secondarySystemGroupedBackground))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 14) {
            iconBadge

            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.title)
                    .font(.headline)

                statusPill

                Text(reminder.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailingColumn
        }
    }

    @ViewBuilder
    private var trailingColumn: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss reminder")
            }

            countdownBadge
        }
    }

    private var iconBadge: some View {
        IconBadge(systemImage: reminder.systemImage, tint: reminder.status.color, size: 48)
    }

    private var statusPill: some View {
        Text(reminder.status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(reminder.status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(reminder.status.color.opacity(0.12), in: Capsule())
    }

    private var countdownBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let value = reminder.countdownValue {
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(reminder.status.color)
                    .contentTransition(.numericText())

                Text(reminder.countdownUnit)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(minWidth: 44)
    }
}
