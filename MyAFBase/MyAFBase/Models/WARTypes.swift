import SwiftUI

/// Broad bucket for a WAR entry — mirrors how most Airmen mentally sort
/// accomplishments before they ever think about EPB/OPB factors.
enum WARCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case job
    case leadership
    case volunteer
    case education
    case deployment
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .job: "Job"
        case .leadership: "Leadership"
        case .volunteer: "Volunteer"
        case .education: "Education"
        case .deployment: "Deployment"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .job: "briefcase.fill"
        case .leadership: "person.3.fill"
        case .volunteer: "heart.fill"
        case .education: "graduationcap.fill"
        case .deployment: "airplane"
        case .other: "square.grid.2x2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .job: AppTheme.info
        case .leadership: AppTheme.brandPrimary
        case .volunteer: AppTheme.success
        case .education: AppTheme.highlight
        case .deployment: AppTheme.warning
        case .other: AppTheme.muted
        }
    }
}

/// The four Air Force performance factors used on both the EPB and OPB.
/// Optional per entry — not every accomplishment maps cleanly to one.
enum WARPerformanceFactor: String, Codable, CaseIterable, Identifiable, Sendable {
    case executingTheMission
    case leadingPeople
    case managingResources
    case improvingTheUnit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .executingTheMission: "Executing the Mission"
        case .leadingPeople: "Leading People"
        case .managingResources: "Managing Resources"
        case .improvingTheUnit: "Improving the Unit"
        }
    }

    var systemImage: String {
        switch self {
        case .executingTheMission: "target"
        case .leadingPeople: "person.2.fill"
        case .managingResources: "chart.pie.fill"
        case .improvingTheUnit: "arrow.up.right.circle.fill"
        }
    }
}

/// Drives EPB vs. OPB terminology throughout the tracker.
enum WARMemberType: String, Codable, CaseIterable, Identifiable, Sendable {
    case enlisted
    case officer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .enlisted: "Enlisted"
        case .officer: "Officer"
        }
    }

    /// The performance report this member type's factors feed into.
    var reportAbbreviation: String {
        switch self {
        case .enlisted: "EPB"
        case .officer: "OPB"
        }
    }
}
