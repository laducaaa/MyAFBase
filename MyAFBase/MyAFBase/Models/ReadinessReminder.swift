import Foundation

struct ReadinessReminder: Identifiable, Equatable {
    let id: String
    let kind: ReadinessItemKind
    let title: String
    let subtitle: String
    let detail: String
    let status: ReadinessStatus
    let systemImage: String
    let sortPriority: Int
    let countdownValue: Int?
    let countdownUnit: String

    static func dismissalID(kind: ReadinessItemKind, tracker: ReadinessTracker) -> String? {
        let calendar = Calendar.current
        let dayKey: (Date) -> String = { date in
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
        }

        switch kind {
        case .fitness:
            guard let date = tracker.fitnessTestDue else { return nil }
            return "readiness-\(kind.rawValue)-\(dayKey(date))"
        case .dental:
            guard let date = tracker.dentalDue else { return nil }
            return "readiness-\(kind.rawValue)-\(dayKey(date))"
        case .eval:
            guard let date = tracker.evalCloseoutDue else { return nil }
            return "readiness-\(kind.rawValue)-\(dayKey(date))"
        case .cac:
            guard let date = tracker.cacExpiration else { return nil }
            return "readiness-\(kind.rawValue)-\(dayKey(date))"
        case .clearance:
            guard let date = tracker.clearanceRenewal else { return nil }
            return "readiness-\(kind.rawValue)-\(dayKey(date))"
        case .pcsWindow:
            guard let start = tracker.pcsWindowStart, let end = tracker.pcsWindowEnd else { return nil }
            return "readiness-\(kind.rawValue)-\(dayKey(start))-\(dayKey(end))"
        }
    }
}

enum ReadinessReminderBuilder {
    static func reminders(
        from tracker: ReadinessTracker,
        relativeTo now: Date = .now
    ) -> [ReadinessReminder] {
        ReadinessItemKind.allCases.compactMap { kind in
            reminder(for: kind, tracker: tracker, relativeTo: now)
        }
        .sorted { lhs, rhs in
            if lhs.sortPriority != rhs.sortPriority {
                return lhs.sortPriority < rhs.sortPriority
            }
            return lhs.title < rhs.title
        }
    }

    private static func reminder(
        for kind: ReadinessItemKind,
        tracker: ReadinessTracker,
        relativeTo now: Date
    ) -> ReadinessReminder? {
        let item = ReadinessCountdownBuilder.buildItem(kind, tracker: tracker, relativeTo: now)
        guard item.countdownValue != nil,
              let dismissalID = ReadinessReminder.dismissalID(kind: kind, tracker: tracker) else {
            return nil
        }

        let status = ReadinessStatus(widgetKey: item.statusRaw)
        let countdown = countdownDisplay(for: item)
        return ReadinessReminder(
            id: dismissalID,
            kind: kind,
            title: item.title,
            subtitle: subtitle(for: item),
            detail: item.detailLabel,
            status: status,
            systemImage: item.systemImage,
            sortPriority: sortPriority(for: item, status: status),
            countdownValue: countdown.value,
            countdownUnit: countdown.unit
        )
    }

    private static func countdownDisplay(for item: ReadinessWidgetItemSnapshot) -> (value: Int?, unit: String) {
        guard let value = item.countdownValue else {
            return (nil, "")
        }

        switch item.countdownLabel {
        case "due today":
            return (0, "today")
        case "day overdue":
            return (1, "day late")
        case "days overdue":
            return (value, "days late")
        case "day":
            return (1, "day")
        case "days":
            return (value, "days")
        case "day left":
            return (1, "day left")
        case "days left":
            return (value, "days left")
        case "day past":
            return (1, "day past")
        case "days past":
            return (value, "days past")
        case "day until open":
            return (1, "until open")
        case "days until open":
            return (value, "until open")
        default:
            return (value, item.countdownLabel)
        }
    }

    private static func subtitle(for item: ReadinessWidgetItemSnapshot) -> String {
        guard let value = item.countdownValue else { return item.countdownLabel }

        switch item.countdownLabel {
        case "due today":
            return "Due today"
        case "day overdue":
            return "Overdue by 1 day"
        case "days overdue":
            return "Overdue by \(value) days"
        case "day":
            return "Due in 1 day"
        case "days":
            return "Due in \(value) days"
        case "day left":
            return "PCS window — 1 day left"
        case "days left":
            return "PCS window — \(value) days left"
        case "day past":
            return "PCS window ended 1 day ago"
        case "days past":
            return "PCS window ended \(value) days ago"
        case "day until open":
            return "PCS window opens in 1 day"
        case "days until open":
            return "PCS window opens in \(value) days"
        default:
            return item.countdownLabel
        }
    }

    private static func sortPriority(for item: ReadinessWidgetItemSnapshot, status: ReadinessStatus) -> Int {
        guard let value = item.countdownValue else { return Int.max }

        switch status {
        case .overdue:
            return value
        case .windowOpen:
            return 1_000 + value
        case .dueSoon:
            return 10_000 + value
        case .onTrack:
            return 100_000 + value
        case .notSet:
            return Int.max
        }
    }
}

private extension ReadinessStatus {
    init(widgetKey: String) {
        switch widgetKey {
        case "overdue": self = .overdue
        case "dueSoon": self = .dueSoon
        case "onTrack": self = .onTrack
        case "windowOpen": self = .windowOpen
        default: self = .notSet
        }
    }
}
