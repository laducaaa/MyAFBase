import Foundation
import SwiftUI

enum ReadinessStatus: Equatable {
    case notSet
    case overdue
    case dueSoon
    case onTrack
    case windowOpen

    var label: String {
        switch self {
        case .notSet: "Not set"
        case .overdue: "Overdue"
        case .dueSoon: "Due soon"
        case .onTrack: "On track"
        case .windowOpen: "Window open"
        }
    }

    var color: Color {
        switch self {
        case .notSet: AppTheme.muted
        case .overdue: AppTheme.danger
        case .dueSoon: AppTheme.warning
        case .onTrack: AppTheme.success
        case .windowOpen: AppTheme.info
        }
    }

    static func evaluate(dueDate: Date?, relativeTo now: Date = .now) -> ReadinessStatus {
        guard let dueDate else { return .notSet }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDue = calendar.startOfDay(for: dueDate)

        if startOfDue < startOfToday {
            return .overdue
        }

        guard let soonThreshold = calendar.date(byAdding: .day, value: 30, to: startOfToday) else {
            return .onTrack
        }

        if startOfDue <= soonThreshold {
            return .dueSoon
        }

        return .onTrack
    }

    static func evaluatePCSWindow(start: Date?, end: Date?, relativeTo now: Date = .now) -> ReadinessStatus {
        guard let start, let end else {
            if start != nil || end != nil {
                return .dueSoon
            }
            return .notSet
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let windowStart = calendar.startOfDay(for: start)
        let windowEnd = calendar.startOfDay(for: end)

        if today >= windowStart && today <= windowEnd {
            return .windowOpen
        }

        if today > windowEnd {
            return .overdue
        }

        return evaluate(dueDate: start, relativeTo: now)
    }
}
