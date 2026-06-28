import Foundation
import WidgetKit

enum ReadinessWidgetSync {
    @MainActor
    static func publish(tracker: ReadinessTracker, baseName: String) {
        let snapshot = ReadinessCountdownBuilder.snapshot(from: tracker, baseName: baseName)
        WidgetDataStore.saveReadiness(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    static func publishActive(
        tracker: ReadinessTracker?,
        baseID: String?,
        baseName: String?
    ) {
        guard let tracker, let baseID, let baseName, tracker.baseID == baseID else {
            return
        }
        publish(tracker: tracker, baseName: baseName)
    }

    @MainActor
    static func publishAll(
        trackers: [ReadinessTracker],
        activeBaseID: String?,
        baseNameProvider: (String) -> String
    ) {
        guard let activeBaseID,
              let tracker = trackers.first(where: { $0.baseID == activeBaseID }) else {
            return
        }
        publish(tracker: tracker, baseName: baseNameProvider(activeBaseID))
    }
}

enum ReadinessCountdownBuilder {
    static func snapshot(
        from tracker: ReadinessTracker,
        baseName: String,
        relativeTo now: Date = .now
    ) -> ReadinessWidgetSnapshot {
        ReadinessWidgetSnapshot(
            activeBaseID: tracker.baseID,
            activeBaseName: baseName,
            items: ReadinessItemKind.allCases.map { buildItem($0, tracker: tracker, relativeTo: now) },
            updatedAt: tracker.updatedAt
        )
    }

    static func buildItem(
        _ kind: ReadinessItemKind,
        tracker: ReadinessTracker,
        relativeTo now: Date = .now
    ) -> ReadinessWidgetItemSnapshot {
        switch kind {
        case .fitness:
            return dueDateItem(kind, dueDate: tracker.fitnessTestDue, relativeTo: now)
        case .dental:
            return dueDateItem(kind, dueDate: tracker.dentalDue, relativeTo: now)
        case .eval:
            return dueDateItem(kind, dueDate: tracker.evalCloseoutDue, relativeTo: now)
        case .cac:
            return dueDateItem(kind, dueDate: tracker.cacExpiration, relativeTo: now)
        case .clearance:
            return dueDateItem(kind, dueDate: tracker.clearanceRenewal, relativeTo: now)
        case .pcsWindow:
            return pcsWindowItem(tracker: tracker, relativeTo: now)
        }
    }

    private static func dueDateItem(
        _ kind: ReadinessItemKind,
        dueDate: Date?,
        relativeTo now: Date
    ) -> ReadinessWidgetItemSnapshot {
        let status = ReadinessStatus.evaluate(dueDate: dueDate, relativeTo: now)
        let calendar = Calendar.current

        guard let dueDate else {
            return ReadinessWidgetItemSnapshot(
                kind: kind.rawValue,
                title: kind.title,
                systemImage: kind.systemImage,
                countdownValue: nil,
                countdownLabel: "Not set",
                detailLabel: "Set in Assignment",
                statusRaw: status.widgetKey
            )
        }

        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: dueDate)
        ).day ?? 0

        let countdownLabel: String
        let countdownValue: Int?
        if days < 0 {
            countdownValue = abs(days)
            countdownLabel = days == -1 ? "day overdue" : "days overdue"
        } else if days == 0 {
            countdownValue = 0
            countdownLabel = "due today"
        } else if days == 1 {
            countdownValue = 1
            countdownLabel = "day"
        } else {
            countdownValue = days
            countdownLabel = "days"
        }

        return ReadinessWidgetItemSnapshot(
            kind: kind.rawValue,
            title: kind.title,
            systemImage: kind.systemImage,
            countdownValue: countdownValue,
            countdownLabel: countdownLabel,
            detailLabel: dueDate.formatted(date: .abbreviated, time: .omitted),
            statusRaw: status.widgetKey
        )
    }

    private static func pcsWindowItem(
        tracker: ReadinessTracker,
        relativeTo now: Date
    ) -> ReadinessWidgetItemSnapshot {
        let kind = ReadinessItemKind.pcsWindow
        let status = ReadinessStatus.evaluatePCSWindow(
            start: tracker.pcsWindowStart,
            end: tracker.pcsWindowEnd,
            relativeTo: now
        )
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        guard let start = tracker.pcsWindowStart, let end = tracker.pcsWindowEnd else {
            return ReadinessWidgetItemSnapshot(
                kind: kind.rawValue,
                title: kind.title,
                systemImage: kind.systemImage,
                countdownValue: nil,
                countdownLabel: "Not set",
                detailLabel: "Set in Assignment",
                statusRaw: status.widgetKey
            )
        }

        let windowStart = calendar.startOfDay(for: start)
        let windowEnd = calendar.startOfDay(for: end)
        let detail = "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"

        if today >= windowStart && today <= windowEnd {
            let daysLeft = calendar.dateComponents([.day], from: today, to: windowEnd).day ?? 0
            return ReadinessWidgetItemSnapshot(
                kind: kind.rawValue,
                title: kind.title,
                systemImage: kind.systemImage,
                countdownValue: max(daysLeft, 0),
                countdownLabel: daysLeft == 1 ? "day left" : "days left",
                detailLabel: detail,
                statusRaw: status.widgetKey
            )
        }

        if today > windowEnd {
            let overdueDays = calendar.dateComponents([.day], from: windowEnd, to: today).day ?? 0
            return ReadinessWidgetItemSnapshot(
                kind: kind.rawValue,
                title: kind.title,
                systemImage: kind.systemImage,
                countdownValue: max(overdueDays, 1),
                countdownLabel: overdueDays == 1 ? "day past" : "days past",
                detailLabel: detail,
                statusRaw: status.widgetKey
            )
        }

        let daysUntilOpen = calendar.dateComponents([.day], from: today, to: windowStart).day ?? 0
        return ReadinessWidgetItemSnapshot(
            kind: kind.rawValue,
            title: kind.title,
            systemImage: kind.systemImage,
            countdownValue: max(daysUntilOpen, 0),
            countdownLabel: daysUntilOpen == 1 ? "day until open" : "days until open",
            detailLabel: detail,
            statusRaw: status.widgetKey
        )
    }
}

private extension ReadinessStatus {
    var widgetKey: String {
        switch self {
        case .notSet: "notSet"
        case .overdue: "overdue"
        case .dueSoon: "dueSoon"
        case .onTrack: "onTrack"
        case .windowOpen: "windowOpen"
        }
    }
}
