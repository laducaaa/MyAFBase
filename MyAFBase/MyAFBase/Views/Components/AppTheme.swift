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
    //
    // One elevation language for the whole app: two corner radii (card, hero)
    // and a single shadow/border recipe applied via `elevatedCardStyle()` /
    // `elevatedHeroStyle()` below. Individual views should not invent their
    // own radius or shadow values — that's what produced the "disjointed"
    // look where every card on Home had a slightly different shape.

    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 12

    /// Standard corner radius for content cards, tiles, and banners.
    static let cardCornerRadius: CGFloat = 20
    /// Larger radius reserved for the single "hero" element per screen, so it
    /// reads as a clear step up in the visual hierarchy from ordinary cards.
    static let heroCornerRadius: CGFloat = 28

    static let cardShadowOpacity: Double = 0.07
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 3

    static let heroShadowOpacity: Double = 0.14

    /// Hairline stroke used in place of a shadow in dark mode, where drop
    /// shadows barely register against a near-black background.
    static var cardStrokeColor: Color { Color.primary.opacity(0.08) }

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

/// The leading icon badge used across Home and Explore cards (reminders,
/// assignment banner, emergency numbers, tool tiles, saved items) so every
/// card announces its category with the same shape and treatment — a tinted
/// rounded square behind an SF Symbol, colored to match the row's meaning.
struct IconBadge: View {
    var systemImage: String
    var tint: Color
    var size: CGFloat = 44
    var style: Style = .tinted

    enum Style {
        /// Soft tinted fill — the default, used for most content cards.
        case tinted
        /// Solid gradient fill with a white glyph — reserved for the rare,
        /// high-urgency badge (e.g. Emergency Numbers).
        case solid
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(style == .solid ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.14)))
                .frame(width: size, height: size)

            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(style == .solid ? .white : tint)
        }
        .accessibilityHidden(true)
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

/// One shared elevation recipe for every card-like surface in the app: a
/// consistent corner radius, a soft shadow in light mode, and a hairline
/// border instead of a shadow in dark mode (where shadows don't read well
/// against near-black backgrounds). Views should reach for this instead of
/// composing their own `.background` + `.clipShape` + `.shadow` stack.
private struct ElevatedSurface: ViewModifier {
    var cornerRadius: CGFloat
    var background: AnyShapeStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(background, in: shape)
            .overlay {
                if colorScheme == .dark {
                    shape.strokeBorder(AppTheme.cardStrokeColor, lineWidth: 1)
                }
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0 : AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius,
                y: AppTheme.cardShadowY
            )
    }
}

/// Same shape/shadow recipe as `ElevatedSurface`, without imposing a
/// background — for views (like tinted bento tiles) that paint their own
/// fill but should still match the app-wide elevation language.
private struct ElevatedOutline: ViewModifier {
    var cornerRadius: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .clipShape(shape)
            .overlay {
                if colorScheme == .dark {
                    shape.strokeBorder(AppTheme.cardStrokeColor, lineWidth: 1)
                }
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0 : AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius,
                y: AppTheme.cardShadowY
            )
    }
}

extension View {
    /// Standard elevated card surface: rounded corners, soft shadow (light) or
    /// hairline border (dark). Use for every content card on Home, Explore, etc.
    func elevatedCardStyle<S: ShapeStyle>(
        cornerRadius: CGFloat = AppTheme.cardCornerRadius,
        background: S = AnyShapeStyle(Color(.systemBackground))
    ) -> some View {
        modifier(ElevatedSurface(cornerRadius: cornerRadius, background: AnyShapeStyle(background)))
    }

    /// Shape/shadow only — pair with a custom `.background` for cards that
    /// need a bespoke fill (gradients, tints) but should still match the
    /// shared corner radius and elevation.
    func elevatedCardOutline(cornerRadius: CGFloat = AppTheme.cardCornerRadius) -> some View {
        modifier(ElevatedOutline(cornerRadius: cornerRadius))
    }

    func appCardStyle(
        padding: CGFloat = 16,
        background: Color = Color(.systemBackground)
    ) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .elevatedCardStyle(background: background)
    }

    func appScreenBackground() -> some View {
        background { AppScreenBackground() }
    }

    func appCardShell(background: Color = Color(.systemBackground)) -> some View {
        elevatedCardStyle(background: background)
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
