import SwiftUI

struct EmptyStateView: View {
    enum Style {
        case inline
        case card
        case prominent
    }

    let systemImage: String
    var title: String?
    let message: String
    var style: Style = .inline
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: contentSpacing) {
            Image(systemName: systemImage)
                .font(iconFont)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)

            VStack(spacing: 6) {
                if let title {
                    Text(title)
                        .font(titleFont)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }

                Text(message)
                    .font(messageFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    .controlSize(.small)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(padding)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .modifier(EmptyStateCardShadow(style: style))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
}

private struct EmptyStateCardShadow: ViewModifier {
    let style: EmptyStateView.Style

    func body(content: Content) -> some View {
        if style == .card {
            content.shadow(
                color: .black.opacity(AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius,
                y: AppTheme.cardShadowY
            )
        } else {
            content
        }
    }
}

extension EmptyStateView {
    private var accessibilityText: String {
        if let title {
            return "\(title). \(message)"
        }
        return message
    }

    private var iconFont: Font {
        switch style {
        case .inline: .title2
        case .card: .title
        case .prominent: .system(size: 44, weight: .light)
        }
    }

    private var iconColor: Color {
        switch style {
        case .inline, .card: AppTheme.accent.opacity(0.85)
        case .prominent: AppTheme.accent
        }
    }

    private var titleFont: Font {
        switch style {
        case .inline: .subheadline.weight(.semibold)
        case .card, .prominent: .headline
        }
    }

    private var messageFont: Font {
        switch style {
        case .inline: .subheadline
        case .card, .prominent: .subheadline
        }
    }

    private var contentSpacing: CGFloat {
        switch style {
        case .inline: 10
        case .card: 12
        case .prominent: 16
        }
    }

    private var padding: EdgeInsets {
        switch style {
        case .inline: EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)
        case .card: EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16)
        case .prominent: EdgeInsets(top: 40, leading: 24, bottom: 40, trailing: 24)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .inline:
            Color.clear
        case .card:
            Color(.systemBackground)
        case .prominent:
            Color.clear
        }
    }

    private var cornerRadius: CGFloat {
        style == .card ? AppTheme.cardCornerRadius : 0
    }
}

extension EmptyStateView {
    static func noBaseSelected(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "building.2",
            title: "No Base Selected",
            message: "Choose your installation to load local resources, alerts, and assignment tools.",
            style: .prominent,
            actionTitle: "Select Base",
            action: action
        )
    }

    static func savedItems(exploreAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "bookmark",
            title: "Nothing Saved Yet",
            message: "Bookmark gates, resources, and events in Explore to see your most recent saves here.",
            style: .card,
            actionTitle: "Browse Explore",
            action: exploreAction
        )
    }

    static func savedGates(exploreAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "door.left.hand.open",
            title: "No Saved Gates",
            message: "Bookmark gates in Explore for quick access to hours, status, and directions.",
            style: .card,
            actionTitle: "Browse Gates",
            action: exploreAction
        )
    }

    static func savedResources(exploreAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "bookmark",
            title: "No Saved Resources",
            message: "Bookmark dining, medical, and other locations to find them here fast.",
            style: .card,
            actionTitle: "Browse Resources",
            action: exploreAction
        )
    }

    static func savedEvents(exploreAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "calendar",
            title: "No Saved Events",
            message: "Bookmark base events in Explore to keep track of what's coming up.",
            style: .card,
            actionTitle: "Browse Events",
            action: exploreAction
        )
    }

    static func allClearAlerts(baseName: String) -> EmptyStateView {
        EmptyStateView(
            systemImage: "checkmark.circle",
            title: "All Clear",
            message: "No active alerts for \(baseName) right now.",
            style: .card
        )
    }
}
