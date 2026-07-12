import SwiftUI

/// Registry of Home-screen tools for the bento grid.
enum HomeToolsCatalog {
    static let all: [HomeTool] = [
        HomeTool(
            id: "pfra-score",
            title: "PFRA Score",
            subtitle: "Estimate your fitness score",
            systemImage: "figure.run",
            tint: AppTheme.info
        ),
        HomeTool(
            id: "pfra-goal",
            title: "PFRA Goals",
            subtitle: "Plan what you need to hit",
            systemImage: "target",
            tint: AppTheme.brandPrimary
        ),
        HomeTool(
            id: "afi-search",
            title: "Essential AFI Search",
            subtitle: "Search essential AFI guidance offline",
            systemImage: "text.magnifyingglass",
            tint: AppTheme.accent
        ),
        HomeTool(
            id: "war-tracker",
            title: "WAR Tracker",
            subtitle: "Log accomplishments for awards and EPB/OPB",
            systemImage: "text.badge.star",
            tint: AppTheme.brandSecondary
        ),
        HomeTool(
            id: "leave-planner",
            title: "Leave Planner",
            subtitle: "Upcoming leave & PCS planning",
            systemImage: "calendar.badge.clock",
            tint: AppTheme.success
        ),
        HomeTool(
            id: "pay-calendar",
            title: "Pay Calendar",
            subtitle: "Mid-month, month-end & special pays",
            systemImage: "dollarsign.circle.fill",
            tint: AppTheme.highlight
        )
    ]
}

struct HomeTool: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
}
