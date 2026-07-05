import SwiftUI

/// Registry of Home-screen tools for the bento grid.
enum HomeToolsCatalog {
    static let all: [HomeTool] = [
        HomeTool(
            id: "pfra-score",
            title: "PFRA Score",
            subtitle: "Estimate your fitness score",
            systemImage: "figure.run",
            tint: AppTheme.info,
            layout: .compact
        ),
        HomeTool(
            id: "pfra-goal",
            title: "PFRA Goals",
            subtitle: "Plan what you need to hit",
            systemImage: "target",
            tint: AppTheme.brandPrimary,
            layout: .compact
        ),
        HomeTool(
            id: "afi-search",
            title: "Essential AFI Search",
            subtitle: "Dress, leave, fitness & more — offline with citations",
            systemImage: "text.magnifyingglass",
            tint: AppTheme.accent,
            layout: .wide
        ),
        HomeTool(
            id: "war-tracker",
            title: "WAR Tracker",
            subtitle: "Log accomplishments as they happen — ready for your next award or EPB/OPB",
            systemImage: "text.badge.star",
            tint: AppTheme.brandSecondary,
            layout: .wide
        ),
        HomeTool(
            id: "leave-planner",
            title: "Leave Planner",
            subtitle: "Upcoming leave & PCS planning",
            systemImage: "calendar.badge.clock",
            tint: AppTheme.success,
            layout: .compact
        ),
        HomeTool(
            id: "pay-calendar",
            title: "Pay Calendar",
            subtitle: "Mid-month, month-end & special pays",
            systemImage: "dollarsign.circle.fill",
            tint: AppTheme.highlight,
            layout: .compact
        )
    ]
}

struct HomeTool: Identifiable {
    enum Layout {
        case compact
        case wide
    }

    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let layout: Layout
}
