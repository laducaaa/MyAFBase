import SwiftUI

enum AppTheme {
    // MARK: - Brand

    static let accent = Color(red: 0.12, green: 0.38, blue: 0.58)
    static let accentLight = Color(red: 0.28, green: 0.52, blue: 0.72)

    static let brandTeal = Color(red: 0.14, green: 0.32, blue: 0.28)
    static let brandTealLight = Color(red: 0.20, green: 0.42, blue: 0.36)

    static let heroBackground = Color(red: 0.13, green: 0.13, blue: 0.14)
    static let heroSecondaryText = Color.white.opacity(0.72)
    static let heroDivider = Color.white.opacity(0.12)

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
            colors: [brandTeal, brandTealLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Adaptive label color for button text — never use accent for button titles.
    static var buttonText: Color { .primary }

    /// Accent color reserved for icons inside buttons, not text.
    static var buttonIcon: Color { accent }
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
                    AppTheme.brandTeal.opacity(0.07),
                    AppTheme.accent.opacity(0.03),
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
