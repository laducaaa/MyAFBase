import SwiftUI

/// Compact bento-style launcher — all tools visible at once without scrolling.
struct HomeToolsBentoGrid: View {
    private let spacing: CGFloat = 10
    private let compactHeight: CGFloat = 104
    private let wideHeight: CGFloat = 92

    private var compactTools: [HomeTool] {
        HomeToolsCatalog.all.filter { $0.layout == .compact }
    }

    private var wideTool: HomeTool? {
        HomeToolsCatalog.all.first { $0.layout == .wide }
    }

    var body: some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(compactTools.prefix(2)) { tool in
                    toolLink(for: tool) {
                        HomeToolBentoTile(tool: tool, style: .compact)
                            .frame(height: compactHeight)
                    }
                }
            }

            if let wideTool {
                toolLink(for: wideTool) {
                    HomeToolBentoTile(tool: wideTool, style: .wide)
                        .frame(height: wideHeight)
                }
            }

            HStack(spacing: spacing) {
                ForEach(compactTools.dropFirst(2)) { tool in
                    toolLink(for: tool) {
                        HomeToolBentoTile(tool: tool, style: .compact)
                            .frame(height: compactHeight)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tools")
    }

    @ViewBuilder
    private func toolLink<Content: View>(for tool: HomeTool, @ViewBuilder content: () -> Content) -> some View {
        NavigationLink {
            destination(for: tool)
        } label: {
            content()
        }
        .buttonStyle(HomeToolBentoButtonStyle())
    }

    @ViewBuilder
    private func destination(for tool: HomeTool) -> some View {
        switch tool.id {
        case "pfra-score":
            PTCalculatorView()
        case "pfra-goal":
            PFRAGoalPlannerView()
        case "afi-search":
            AFISearchToolView()
        case "leave-planner":
            LeavePlannerView()
        case "pay-calendar":
            PayCalendarView()
        default:
            EmptyView()
        }
    }
}

// MARK: - Tile

private struct HomeToolBentoTile: View {
    let tool: HomeTool
    let style: HomeTool.Layout

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            tileBackground

            if style == .wide {
                wideContent
            } else {
                compactContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderLineWidth)
        }
        .shadow(color: tileShadowColor, radius: tileShadowRadius, y: tileShadowY)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tool.title). \(tool.subtitle)")
        .accessibilityHint("Opens \(tool.title)")
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: tool.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            Text(tool.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(titleColor)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var wideContent: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: tool.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(tool.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)

                Text(tool.subtitle)
                    .font(.caption)
                    .foregroundStyle(subtitleColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(iconColor.opacity(0.85))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var tileBackground: some View {
        Group {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tool.tint.opacity(0.34),
                                tool.tint.opacity(0.14),
                                Color(.secondarySystemGroupedBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
            }
        }
    }

    private var iconColor: Color {
        colorScheme == .dark ? tool.tint.opacity(0.95) : tool.tint
    }

    private var titleColor: Color {
        .primary
    }

    private var subtitleColor: Color {
        .secondary
    }

    private var borderColor: Color {
        if colorScheme == .dark {
            tool.tint.opacity(0.28)
        } else {
            Color.black.opacity(0.06)
        }
    }

    private var borderLineWidth: CGFloat {
        colorScheme == .dark ? 0.5 : 0.5
    }

    private var tileShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.28) : .black.opacity(AppTheme.cardShadowOpacity)
    }

    private var tileShadowRadius: CGFloat {
        colorScheme == .dark ? 8 : AppTheme.cardShadowRadius
    }

    private var tileShadowY: CGFloat {
        colorScheme == .dark ? 3 : AppTheme.cardShadowY
    }
}

private struct HomeToolBentoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

#if DEBUG
#Preview("Bento Grid") {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Tools")
                HomeToolsBentoGrid()
            }
            .padding()
        }
    }
}
#endif
