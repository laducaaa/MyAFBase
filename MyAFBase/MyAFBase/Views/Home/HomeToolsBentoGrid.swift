import SwiftUI

/// Compact 2×3 bento launcher — all tools visible at once without scrolling.
struct HomeToolsBentoGrid: View {
    private let spacing: CGFloat = 10
    private let tileHeight: CGFloat = 104

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(HomeToolsCatalog.all) { tool in
                NavigationLink {
                    destination(for: tool)
                } label: {
                    HomeToolBentoTile(tool: tool)
                        .frame(height: tileHeight)
                }
                .buttonStyle(HomeToolBentoButtonStyle())
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tools")
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
        case "war-tracker":
            WARTrackerToolView()
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

    var body: some View {
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
        .elevatedCardStyle(background: Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tool.title)
        .accessibilityHint("Opens \(tool.title)")
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
