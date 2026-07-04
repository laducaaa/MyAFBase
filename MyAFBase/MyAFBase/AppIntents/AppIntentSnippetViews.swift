import SwiftUI
import UIKit

enum AppIntentSnippetPalette {
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(uiColor: .tertiaryLabel)

    static let payAccent = AppTheme.highlight

    static func reminderAccent(for status: ReadinessStatus) -> Color {
        switch status {
        case .overdue: AppTheme.danger
        case .dueSoon: AppTheme.warning
        case .onTrack: AppTheme.success
        case .windowOpen: AppTheme.info
        case .notSet: AppTheme.muted
        }
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
