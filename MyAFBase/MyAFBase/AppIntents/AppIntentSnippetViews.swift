import SwiftUI
import UIKit

enum AppIntentSnippetPalette {
    static let primaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.95, alpha: 1)
            : UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1)
    })

    static let secondaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.78, alpha: 1)
            : UIColor(red: 0.28, green: 0.32, blue: 0.38, alpha: 1)
    })

    static let tertiaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.62, alpha: 1)
            : UIColor(red: 0.42, green: 0.46, blue: 0.52, alpha: 1)
    })

    static let payAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.98, green: 0.78, blue: 0.22, alpha: 1)
            : UIColor(red: 0.72, green: 0.52, blue: 0.04, alpha: 1)
    })

    static func reminderAccent(for status: ReadinessStatus) -> Color {
        Color(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            switch status {
            case .overdue:
                return isDark
                    ? UIColor(red: 1.0, green: 0.35, blue: 0.33, alpha: 1)
                    : UIColor(red: 0.78, green: 0.12, blue: 0.14, alpha: 1)
            case .dueSoon:
                return isDark
                    ? UIColor(red: 1.0, green: 0.62, blue: 0.20, alpha: 1)
                    : UIColor(red: 0.82, green: 0.42, blue: 0.04, alpha: 1)
            case .onTrack:
                return isDark
                    ? UIColor(red: 0.35, green: 0.82, blue: 0.48, alpha: 1)
                    : UIColor(red: 0.10, green: 0.52, blue: 0.28, alpha: 1)
            case .windowOpen:
                return isDark
                    ? UIColor(red: 0.40, green: 0.68, blue: 1.0, alpha: 1)
                    : UIColor(red: 0.08, green: 0.38, blue: 0.78, alpha: 1)
            case .notSet:
                return isDark
                    ? UIColor(white: 0.78, alpha: 1)
                    : UIColor(red: 0.28, green: 0.32, blue: 0.38, alpha: 1)
            }
        })
    }
}

private struct AppIntentSnippetContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .tint(AppIntentSnippetPalette.primaryText)
    }
}

struct NextPaySnippetView: View {
    let snapshot: PayWidgetSnapshot

    var body: some View {
        AppIntentSnippetContainer {
            if snapshot.isAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(snapshot.nextTitle)
                            .foregroundStyle(AppIntentSnippetPalette.primaryText)
                    } icon: {
                        Image(systemName: snapshot.symbolName)
                            .foregroundStyle(AppIntentSnippetPalette.payAccent)
                    }
                    .font(.headline)

                    Text(snapshot.nextDateLabel)
                        .font(.subheadline)
                        .foregroundStyle(AppIntentSnippetPalette.secondaryText)

                    Text(snapshot.daysLabel)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppIntentSnippetPalette.payAccent)
                }
            } else {
                Label {
                    Text("No upcoming pay date yet")
                        .foregroundStyle(AppIntentSnippetPalette.primaryText)
                } icon: {
                    Image(systemName: "dollarsign.circle")
                        .foregroundStyle(AppIntentSnippetPalette.secondaryText)
                }
                .font(.subheadline)
            }
        }
    }
}

struct NextReminderSnippetView: View {
    let reminder: ReadinessReminder

    var body: some View {
        AppIntentSnippetContainer {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(reminder.title)
                        .foregroundStyle(AppIntentSnippetPalette.primaryText)
                } icon: {
                    Image(systemName: reminder.systemImage)
                        .foregroundStyle(AppIntentSnippetPalette.reminderAccent(for: reminder.status))
                }
                .font(.headline)

                Text(reminder.subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppIntentSnippetPalette.reminderAccent(for: reminder.status))

                Text(reminder.detail)
                    .font(.caption)
                    .foregroundStyle(AppIntentSnippetPalette.tertiaryText)
            }
        }
    }
}

struct EmptyReminderSnippetView: View {
    let message: String

    var body: some View {
        AppIntentSnippetContainer {
            Label {
                Text(message)
                    .foregroundStyle(AppIntentSnippetPalette.secondaryText)
            } icon: {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(AppIntentSnippetPalette.secondaryText)
            }
            .font(.subheadline)
        }
    }
}

struct SwitchBaseSnippetView: View {
    let baseName: String
    let location: String

    var body: some View {
        AppIntentSnippetContainer {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(baseName)
                        .foregroundStyle(AppIntentSnippetPalette.primaryText)
                } icon: {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(AppIntentSnippetPalette.payAccent)
                }
                .font(.headline)

                if !location.isEmpty {
                    Text(location)
                        .font(.subheadline)
                        .foregroundStyle(AppIntentSnippetPalette.secondaryText)
                }

                Text("Active installation")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppIntentSnippetPalette.tertiaryText)
            }
        }
    }
}
