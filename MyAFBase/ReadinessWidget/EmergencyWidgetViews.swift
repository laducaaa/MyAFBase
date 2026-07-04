import SwiftUI
import WidgetKit

struct EmergencyWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    let entry: EmergencyWidgetEntry

    private var snapshot: EmergencyWidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(systemImage: "phone.circle.fill", title: snapshot.baseName)

            Group {
                switch family {
                case .systemSmall:
                    smallContent
                case .systemMedium:
                    mediumContent
                default:
                    smallContent
                }
            }
            .padding(.top, contentTopSpacing)

            Spacer(minLength: 0)
        }
        .padding(contentPadding)
        .containerBackground(for: .widget) {
            WidgetPalette.background(for: colorScheme)
        }
    }

    @ViewBuilder
    private var smallContent: some View {
        if let contact = entry.selectedContact {
            EmergencyContactDetail(contact: contact)
        } else if snapshot.contacts.isEmpty {
            emptyState(message: "Open MyAFBase to load base contacts.")
        } else {
            emptyState(message: "Edit widget to pick an emergency number.")
        }
    }

    @ViewBuilder
    private var mediumContent: some View {
        let contacts = Array(snapshot.contacts.prefix(3))

        if contacts.isEmpty {
            emptyState(message: "Open MyAFBase to load base contacts.")
        } else {
            EmergencyMediumGrid(contacts: contacts)
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No contact selected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
            Text(message)
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(2)
        }
    }

    private var contentPadding: EdgeInsets {
        switch family {
        case .systemMedium:
            EdgeInsets(top: 10, leading: 12, bottom: 12, trailing: 12)
        default:
            EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        }
    }

    private var contentTopSpacing: CGFloat {
        family == .systemSmall ? 10 : 8
    }
}

// MARK: - Small (one configurable contact)

private struct EmergencyContactDetail: View {
    @Environment(\.colorScheme) private var colorScheme

    let contact: EmergencyContactSnapshot

    private var accentColor: Color {
        contact.isUniversalEmergency
            ? WidgetPalette.danger(for: colorScheme)
            : WidgetPalette.statusColor(for: "overdue", colorScheme: colorScheme)
    }

    var body: some View {
        if let url = phoneURL(for: contact.number) {
            Link(destination: url) {
                detailContent
            }
        } else {
            detailContent
        }
    }

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: contact.systemImage)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(contact.number)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "phone.fill")
                    .font(.caption.weight(.bold))
                Text("Tap to call")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(accentColor)
        }
    }

    private func phoneURL(for number: String) -> URL? {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }
}

// MARK: - Medium (1×3 grid)

private struct EmergencyMediumGrid: View {
    let contacts: [EmergencyContactSnapshot]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                if index > 0 {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 1)
                        .padding(.vertical, 2)
                }

                EmergencyGridCell(contact: contact)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct EmergencyGridCell: View {
    @Environment(\.colorScheme) private var colorScheme

    let contact: EmergencyContactSnapshot

    private var accentColor: Color {
        contact.isUniversalEmergency
            ? WidgetPalette.danger(for: colorScheme)
            : WidgetPalette.statusColor(for: "overdue", colorScheme: colorScheme)
    }

    var body: some View {
        if let url = phoneURL(for: contact.number) {
            Link(destination: url) {
                cellContent
            }
        } else {
            cellContent
        }
    }

    private var cellContent: some View {
        VStack(spacing: 5) {
            Image(systemName: contact.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(accentColor)

            Text(shortLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(contact.number)
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Image(systemName: "phone.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(accentColor)
        }
        .padding(.horizontal, 4)
    }

    private var shortLabel: String {
        if contact.isUniversalEmergency { return "911" }
        if contact.label.localizedCaseInsensitiveContains("security") { return "Security" }
        if contact.label.localizedCaseInsensitiveContains("hospital") { return "Hospital" }
        if contact.label.localizedCaseInsensitiveContains("fire") { return "Fire" }
        return contact.label
    }

    private func phoneURL(for number: String) -> URL? {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }
}
