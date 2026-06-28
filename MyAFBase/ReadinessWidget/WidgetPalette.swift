import SwiftUI

struct WidgetHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }
}

enum WidgetPalette {
    static func background(for colorScheme: ColorScheme) -> some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.32, blue: 0.50).opacity(0.55),
                        Color(red: 0.07, green: 0.08, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.94, blue: 0.99),
                        Color(red: 0.96, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    static func weatherAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.45, green: 0.78, blue: 1.0)
            : Color(red: 0.08, green: 0.38, blue: 0.72)
    }

    static func openNowAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.35, green: 0.82, blue: 0.48)
            : Color(red: 0.10, green: 0.52, blue: 0.28)
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(white: 0.95)
            : Color(red: 0.08, green: 0.10, blue: 0.14)
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(white: 0.72)
            : Color(red: 0.28, green: 0.32, blue: 0.38)
    }

    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(white: 0.55)
            : Color(red: 0.42, green: 0.46, blue: 0.52)
    }

    static func statusColor(for statusRaw: String, colorScheme: ColorScheme) -> Color {
        switch statusRaw {
        case "overdue":
            return colorScheme == .dark
                ? Color(red: 1.0, green: 0.35, blue: 0.33)
                : Color(red: 0.78, green: 0.12, blue: 0.14)
        case "dueSoon":
            return colorScheme == .dark
                ? Color(red: 1.0, green: 0.62, blue: 0.20)
                : Color(red: 0.82, green: 0.42, blue: 0.04)
        case "onTrack":
            return colorScheme == .dark
                ? Color(red: 0.35, green: 0.82, blue: 0.48)
                : Color(red: 0.10, green: 0.52, blue: 0.28)
        case "windowOpen":
            return colorScheme == .dark
                ? Color(red: 0.40, green: 0.68, blue: 1.0)
                : Color(red: 0.08, green: 0.38, blue: 0.78)
        default:
            return secondaryText(for: colorScheme)
        }
    }
}
