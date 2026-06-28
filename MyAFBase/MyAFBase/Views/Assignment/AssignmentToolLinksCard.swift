import SwiftUI

enum AssignmentToolLink: Identifiable {
    case pfraCalculator
    case pfraGoalPlanner
    case leavePlanner

    var id: String {
        switch self {
        case .pfraCalculator: "pfra-calculator"
        case .pfraGoalPlanner: "pfra-goal-planner"
        case .leavePlanner: "leave-planner"
        }
    }

    var title: String {
        switch self {
        case .pfraCalculator: "PFRA Score Calculator"
        case .pfraGoalPlanner: "PFRA Goal Planner"
        case .leavePlanner: "Leave Planner"
        }
    }

    var subtitle: String {
        switch self {
        case .pfraCalculator: "Estimate your current composite score"
        case .pfraGoalPlanner: "See what you need for your target tier"
        case .leavePlanner: "Plan leave before you PCS"
        }
    }

    var systemImage: String {
        switch self {
        case .pfraCalculator: "figure.run"
        case .pfraGoalPlanner: "target"
        case .leavePlanner: "calendar.badge.clock"
        }
    }
}

struct AssignmentToolLinksCard: View {
    let links: [AssignmentToolLink]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssignmentSectionHeader(
                title: "Helpful tools",
                subtitle: "Jump straight into planning from your assignment."
            )

            ForEach(links) { link in
                NavigationLink {
                    destination(for: link)
                } label: {
                    HomeToolCard(
                        title: link.title,
                        subtitle: link.subtitle,
                        systemImage: link.systemImage
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destination(for link: AssignmentToolLink) -> some View {
        switch link {
        case .pfraCalculator:
            PTCalculatorView()
        case .pfraGoalPlanner:
            PFRAGoalPlannerView()
        case .leavePlanner:
            LeavePlannerView()
        }
    }
}
