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

    var body: some View {
        Group {
            if style == .wide {
                wideContent
            } else {
                compactContent
            }
        }
        .elevatedCardStyle(background: Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tool.title). \(tool.subtitle)")
        .accessibilityHint("Opens \(tool.title)")
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            IconBadge(systemImage: tool.systemImage, tint: tool.tint, size: 38)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            Text(tool.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var wideContent: some View {
        HStack(alignment: .center, spacing: 14) {
            IconBadge(systemImage: tool.systemImage, tint: tool.tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(tool.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(tool.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
