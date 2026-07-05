import Foundation

/// How entries are ordered/sectioned when generating report text.
enum WAROutputGrouping: String, CaseIterable, Identifiable, Sendable {
    case chronological
    case category
    case performanceFactor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chronological: "Chronological"
        case .category: "By Category"
        case .performanceFactor: "By Factor"
        }
    }
}

/// How each entry is rendered within the generated report text.
enum WAROutputFormat: String, CaseIterable, Identifiable, Sendable {
    case plainText
    case draftBullets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plainText: "Plain Text"
        case .draftBullets: "Draft Bullets"
        }
    }

    var helpText: String {
        switch self {
        case .plainText: "Full detail per entry — good for email or a narrative summary."
        case .draftBullets: "One condensed line per entry — a starting point for award or eval bullets."
        }
    }
}

/// Quick date-range presets for the Reports screen.
enum WARDateRangePreset: String, CaseIterable, Identifiable, Sendable {
    case thisWeek
    case thisMonth
    case thisQuarter
    case thisYear
    case closeoutCycle
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        case .thisQuarter: "This Quarter"
        case .thisYear: "This Year"
        case .closeoutCycle: "EPB/OPB Cycle"
        case .custom: "Custom"
        }
    }
}

/// Tone of voice for a generated award nomination / citation draft.
enum WARCitationTone: String, CaseIterable, Identifiable, Sendable {
    case concise
    case standard
    case formal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .concise: "Concise"
        case .standard: "Standard"
        case .formal: "Formal"
        }
    }
}

/// The echelon a nomination is being written for — flavors the opening line.
enum WARAwardLevel: String, CaseIterable, Identifiable, Sendable {
    case squadron
    case group
    case wing
    case majcom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .squadron: "Squadron"
        case .group: "Group"
        case .wing: "Wing"
        case .majcom: "MAJCOM"
        }
    }
}

/// Read-only counts used to render the summary card on the Reports screen.
struct WAROutputSummary {
    var totalEntries: Int
    var totalHours: Double
    var categoryCounts: [(category: WARCategory, count: Int)]
    var factorCounts: [(factor: WARPerformanceFactor, count: Int)]

    static let empty = WAROutputSummary(totalEntries: 0, totalHours: 0, categoryCounts: [], factorCounts: [])
}
