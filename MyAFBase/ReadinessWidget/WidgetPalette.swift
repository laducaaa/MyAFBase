import SwiftUI
import UIKit

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
                        Color(hex: "2898EB").opacity(0.55),
                        Color(hex: "121214")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: "48B0FF").opacity(0.14),
                        Color(hex: "6EC2FF").opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    static func weatherAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "6EC2FF")
            : Color(hex: "2898EB")
    }

    static func payAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "FFE040")
            : Color(hex: "FFC800")
    }

    static func openNowAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "58E0A0")
            : Color(hex: "30C97E")
    }

    static func warAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "48DDE8")
            : Color(hex: "1EC4D4")
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        Color.primary
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        Color.secondary
    }

    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? "8E8E93" : "98989D")
    }

    static func danger(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "F06B6B") : Color(hex: "C23B3B")
    }

    static func info(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "78C8FF") : Color(hex: "38A8F8")
    }

    static func statusColor(for statusRaw: String, colorScheme: ColorScheme) -> Color {
        switch statusRaw {
        case "overdue":
            return colorScheme == .dark
                ? Color(hex: "F06B6B")
                : Color(hex: "C23B3B")
        case "dueSoon":
            return colorScheme == .dark
                ? Color(hex: "F0A830")
                : Color(hex: "C97814")
        case "onTrack":
            return colorScheme == .dark
                ? Color(hex: "58E0A0")
                : Color(hex: "30C97E")
        case "windowOpen":
            return info(for: colorScheme)
        default:
            return secondaryText(for: colorScheme)
        }
    }
}

// MARK: - Hex color helpers (mirrors AppTheme for widget target)

private extension Color {
    init(hex: String, opacity: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: opacity))
    }
}

private extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red, green, blue: CGFloat
        switch sanitized.count {
        case 6:
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
        default:
            red = 0
            green = 0
            blue = 0
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
