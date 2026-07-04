import SwiftUI
import UIKit

enum AppTheme {
    // MARK: - Brand

    static var brandPrimary: Color { adaptive(light: "2898EB", dark: "6EC2FF") }
    /// Primary interactive accent — links, icon badges, steppers, tool icons.
    static var accent: Color { brandPrimary }
    static var accentLight: Color { adaptive(light: "48B0FF", dark: "8AD4FF") }

    static var brandSecondary: Color { adaptive(light: "1EC4D4", dark: "48DDE8") }
    /// Legacy alias used across the app.
    static var brandTeal: Color { brandSecondary }
    static var brandSecondaryLight: Color { adaptive(light: "3ED8E8", dark: "68E8F4") }
    static var brandTealLight: Color { brandSecondaryLight }

    static var onBrand: Color { .white }

    // MARK: - Semantic status

    static var success: Color { adaptive(light: "30C97E", dark: "58E0A0") }
    static var warning: Color { adaptive(light: "C97814", dark: "F0A830") }
    static var danger: Color { adaptive(light: "C23B3B", dark: "F06B6B") }
    static var info: Color { adaptive(light: "38A8F8", dark: "78C8FF") }
    static var muted: Color { adaptive(light: "8E8E93", dark: "98989D") }
    static var highlight: Color { adaptive(light: "FFC800", dark: "FFE040") }

    // MARK: - Hero & surfaces

    static var heroBackground: Color { adaptive(light: "1E1E20", dark: "121214") }
    static var heroSecondaryText: Color { Color.white.opacity(0.78) }
    static var heroDivider: Color { Color.white.opacity(0.14) }

    // MARK: - Layout

    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let cardSpacing: CGFloat = 12

    static let cardCornerRadius: CGFloat = 16
    static let cardShadowOpacity: Double = 0.07
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 3

    static let heroCornerRadius: CGFloat = 16
    static let heroShadowOpacity: Double = 0.14

    // MARK: - Gradients

    static var brandIconGradient: LinearGradient {
        LinearGradient(
            colors: [brandSecondary, brandSecondaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func phaseGradientColors(for segment: AssignmentSegment, colorScheme: ColorScheme = .light) -> [Color] {
        switch (segment, colorScheme) {
        case (.inbound, .dark):
            return [Color(hex: "4AA4FF"), Color(hex: "72C8FF")]
        case (.inbound, _):
            return [Color(hex: "2088F0"), Color(hex: "48B0FF")]
        case (.stationed, .dark):
            return [Color(hex: "3AB8E8"), Color(hex: "52D0F5")]
        case (.stationed, _):
            return [Color(hex: "1A9FD4"), Color(hex: "2EB8E8")]
        case (.outbound, .dark):
            return [Color(hex: "7B80FF"), Color(hex: "969BFF")]
        case (.outbound, _):
            return [Color(hex: "5E63F0"), Color(hex: "787DF8")]
        }
    }

    /// Adaptive label color for button text — never use accent for button titles.
    static var buttonText: Color { .primary }

    /// Accent color reserved for icons inside buttons, not text.
    static var buttonIcon: Color { accent }

    // MARK: - Private

    private static func adaptive(light: String, dark: String) -> Color {
        Color.adaptiveUIColor(lightHex: light, darkHex: dark)
    }
}

struct AppAccentIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(AppTheme.buttonIcon)
            configuration.title
                .foregroundStyle(AppTheme.buttonText)
        }
    }
}

struct AppPlainTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppTheme.buttonText)
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

struct AppScreenBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)

            LinearGradient(
                colors: [
                    AppTheme.brandSecondary.opacity(0.07),
                    AppTheme.brandPrimary.opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.7, y: 0.45)
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func appCardStyle(
        padding: CGFloat = 16,
        background: Color = Color(.systemBackground)
    ) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius,
                y: AppTheme.cardShadowY
            )
    }

    func appScreenBackground() -> some View {
        background { AppScreenBackground() }
    }

    func appCardShell(background: Color = Color(.systemBackground)) -> some View {
        self
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius,
                y: AppTheme.cardShadowY
            )
    }

    func appButtonTextForeground() -> some View {
        foregroundStyle(AppTheme.buttonText)
    }
}

// MARK: - Hex color helpers

extension Color {
    init(hex: String, opacity: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: opacity))
    }

    static func adaptiveUIColor(lightHex: String, darkHex: String) -> Color {
        Color(
            uiColor: UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? darkHex : lightHex
                return UIColor(hex: hex)
            }
        )
    }
}

extension UIColor {
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
