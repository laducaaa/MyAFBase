import Foundation
import SwiftUI

enum ResourceCategory: String, Codable, CaseIterable, Sendable {
    case dining
    case recreation
    case services
    case shopping
    case fitness
    case medical
    case finance
    case housing
    case safety
    case other

    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .dining: return "fork.knife"
        case .recreation: return "figure.run"
        case .services: return "wrench.and.screwdriver"
        case .shopping: return "bag"
        case .fitness: return "dumbbell"
        case .medical: return "heart.text.square"
        case .finance: return "dollarsign.circle"
        case .housing: return "house"
        case .safety: return "shield"
        case .other: return "ellipsis.circle"
        }
    }
}

enum ResourceType: String, Codable, Sendable {
    case phone
    case url
    case hours
    case location
    case text
}

enum ExploreCategory: String, CaseIterable, Identifiable {
    case all
    case gates
    case dining
    case medical
    case shopping
    case finance
    case housing
    case fitness
    case services
    case recreation
    case safety

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .gates: return "Gates"
        default: return rawValue.capitalized
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .gates: return "door.left.hand.open"
        case .dining: return "fork.knife"
        case .medical: return "heart.text.square"
        case .shopping: return "bag"
        case .finance: return "dollarsign.circle"
        case .housing: return "house"
        case .fitness: return "dumbbell"
        case .services: return "person.2"
        case .recreation: return "figure.run"
        case .safety: return "shield"
        }
    }

    var resourceCategory: ResourceCategory? {
        switch self {
        case .all, .gates: return nil
        case .dining: return .dining
        case .medical: return .medical
        case .shopping: return .shopping
        case .finance: return .finance
        case .housing: return .housing
        case .fitness: return .fitness
        case .services: return .services
        case .recreation: return .recreation
        case .safety: return .safety
        }
    }

    static var resourcesCategories: [ExploreCategory] {
        [.all, .gates, .dining, .medical, .shopping, .finance, .housing, .fitness, .services, .recreation, .safety]
    }
}

enum EventCategory: String, Codable, CaseIterable, Sendable {
    case holiday
    case family
    case outdoor
    case community
    case fitness

    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .holiday: return "tree"
        case .family: return "figure.and.child.holdinghands"
        case .outdoor: return "tent"
        case .community: return "person.3"
        case .fitness: return "figure.run"
        }
    }
}

enum EventExploreCategory: String, CaseIterable, Identifiable {
    case all
    case holiday
    case family
    case outdoor
    case community
    case fitness

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .holiday: return "tree"
        case .family: return "figure.and.child.holdinghands"
        case .outdoor: return "tent"
        case .community: return "person.3"
        case .fitness: return "figure.run"
        }
    }

    var eventCategory: EventCategory? {
        switch self {
        case .all: return nil
        case .holiday: return .holiday
        case .family: return .family
        case .outdoor: return .outdoor
        case .community: return .community
        case .fitness: return .fitness
        }
    }
}

enum GateStatus: String, Codable, Sendable {
    case open
    case closed
    case delayed
    case unknown

    var displayName: String {
        rawValue.capitalized
    }

    /// Single source of truth for status color so every card (StatusPill,
    /// GateCard badge, detail sheets) tints the same status identically.
    var color: Color {
        switch self {
        case .open: AppTheme.success
        case .closed: AppTheme.danger
        case .delayed: AppTheme.warning
        case .unknown: AppTheme.muted
        }
    }
}

enum TrafficLevel: String, Codable, Sendable {
    case none
    case low
    case moderate
    case high
    case unknown

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .none: AppTheme.muted
        case .low: AppTheme.success
        case .moderate: AppTheme.warning
        case .high: AppTheme.danger
        case .unknown: AppTheme.muted
        }
    }
}

enum NotificationType: String, Codable, CaseIterable, Sendable {
    case alert
    case info
    case closure
    case event

    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .alert: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .closure: return "xmark.octagon.fill"
        case .event: return "calendar"
        }
    }

    var filterSystemImage: String {
        switch self {
        case .alert: return "exclamationmark.triangle"
        case .info: return "info.circle"
        case .closure: return "xmark.octagon"
        case .event: return "calendar"
        }
    }
}

enum BookmarkItemType: String, Codable {
    case gate
    case resource
    case event
}

enum HomeSavedCategory: String, CaseIterable, Identifiable {
    case all
    case gates
    case resources
    case events

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: "All"
        case .gates: "Gates"
        case .resources: "Resources"
        case .events: "Events"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "bookmark.fill"
        case .gates: "door.left.hand.open"
        case .resources: "square.grid.2x2"
        case .events: "calendar"
        }
    }

    var itemData: ExploreCategoryItemData {
        ExploreCategoryItemData(id: id, displayName: displayName, systemImage: systemImage)
    }

    var bookmarkItemType: BookmarkItemType? {
        switch self {
        case .all: nil
        case .gates: .gate
        case .resources: .resource
        case .events: .event
        }
    }

    var exploreDestination: ExploreDestination {
        switch self {
        case .all, .resources: .resources
        case .gates: .gates
        case .events: .events
        }
    }
}

enum ExploreSegment: String, CaseIterable {
    case resources = "Resources"
    case events = "Events"
}

enum ExploreDisplayMode: String, CaseIterable, Identifiable {
    case list
    case map

    var id: String { rawValue }

    var title: String {
        switch self {
        case .list: "List"
        case .map: "Map"
        }
    }

    var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .map: "map"
        }
    }
}
