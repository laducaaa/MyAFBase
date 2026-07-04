import SwiftUI

struct NotificationRow: View {
    enum Style {
        case plain
        case card
    }

    let notification: NotificationItem
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
                    .appCardStyle(padding: 14)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 40, height: 40)

                Image(systemName: notification.type.systemImage)
                    .foregroundStyle(iconColor)
                    .font(.body.weight(.semibold))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(notification.postedAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss notification")
            }
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case .alert: return AppTheme.danger
        case .info: return AppTheme.info
        case .closure: return AppTheme.warning
        case .event: return AppTheme.highlight
        }
    }
}
