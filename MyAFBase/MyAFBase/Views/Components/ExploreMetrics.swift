import SwiftUI

enum ExploreMetrics {
    static let cardCornerRadius = AppTheme.cardCornerRadius
    static let cardShadowOpacity = AppTheme.cardShadowOpacity
    static let cardShadowRadius = AppTheme.cardShadowRadius

    static let categoryIconFont: Font = .system(size: 22, weight: .regular)
    static let categoryLabelFont: Font = .system(size: 11, weight: .medium)
    static let categoryItemWidth: CGFloat = 58
    static let categoryUnderlineHeight: CGFloat = 2

    static let cardTitleFont: Font = .system(size: 17, weight: .semibold)
    static let cardRowFont: Font = .system(size: 15, weight: .regular)
    static let cardRowIconFont: Font = .system(size: 15, weight: .medium)
    static let cardRowIconWidth: CGFloat = 20
    static let cardRowSpacing: CGFloat = 8

    static let footerLabelFont: Font = .system(size: 12, weight: .regular)
    static let footerValueFont: Font = .system(size: 12, weight: .medium)
    static let footerIconFont: Font = .system(size: 12, weight: .medium)

    static let bookmarkIconFont: Font = .system(size: 18, weight: .regular)

    static let segmentFont: Font = .system(size: 15, weight: .semibold)
    static let segmentHorizontalPadding: CGFloat = 22
    static let segmentVerticalPadding: CGFloat = 10
    static let segmentMinWidth: CGFloat = 108
}

extension View {
    func exploreCardStyle() -> some View {
        appCardShell()
    }
}

struct ExploreRowLabel: View {
    let systemImage: String
    let text: String
    var underlined: Bool = false
    var foreground: Color = .secondary

    var body: some View {
        HStack(spacing: ExploreMetrics.cardRowSpacing) {
            Image(systemName: systemImage)
                .font(ExploreMetrics.cardRowIconFont)
                .frame(width: ExploreMetrics.cardRowIconWidth, alignment: .center)
                .foregroundStyle(underlined ? AppTheme.buttonIcon : foreground)
            Text(text)
                .font(ExploreMetrics.cardRowFont)
                .underline(underlined)
                .multilineTextAlignment(.leading)
                .foregroundStyle(underlined ? AppTheme.buttonText : foreground)
        }
    }
}
