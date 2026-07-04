import Foundation

enum PayEventKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case midMonth
    case monthEnd

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midMonth: "Mid-month pay"
        case .monthEnd: "Month-end pay"
        }
    }

    var subtitle: String {
        switch self {
        case .midMonth: "Typically the 15th"
        case .monthEnd: "Typically the 1st"
        }
    }

    var systemImage: String {
        switch self {
        case .midMonth: "dollarsign.circle.fill"
        case .monthEnd: "banknote.fill"
        }
    }
}

struct PayCalendarEvent: Identifiable, Equatable, Sendable {
    let id: String
    let kind: PayEventKind
    let date: Date
    let isSpecial: Bool
    let specialTitle: String?

    var title: String {
        if let specialTitle, isSpecial {
            return specialTitle
        }
        return kind.title
    }

    var systemImage: String {
        if isSpecial { return "star.circle.fill" }
        return kind.systemImage
    }
}

struct SpecialPayEntry: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var title: String
    var date: Date
    var notes: String?

    init(id: String = UUID().uuidString, title: String, date: Date, notes: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.notes = notes
    }
}

enum PayCalendar {
    /// Gaps longer than this many calendar days are flagged (strictly greater than two weeks).
    static let longGapThresholdDays = 14
    /// Pays landing within this many days of each other are flagged as clustered.
    static let shortGapThresholdDays = 10

    static let typicalGapDays = 14...17

    static func upcomingEvents(
        from start: Date = .now,
        monthsAhead: Int = 14,
        specialPays: [SpecialPayEntry] = [],
        calendar: Calendar = .current
    ) -> [PayCalendarEvent] {
        let today = calendar.startOfDay(for: start)
        guard let rangeEnd = calendar.date(byAdding: .month, value: monthsAhead, to: today) else {
            return []
        }

        var events: [PayCalendarEvent] = []

        var monthCursor = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        while monthCursor <= rangeEnd {
            for kind in PayEventKind.allCases {
                guard let payDate = payDate(for: kind, in: monthCursor, calendar: calendar) else { continue }
                guard payDate >= today else { continue }

                events.append(
                    PayCalendarEvent(
                        id: "\(kind.rawValue)-\(payDate.timeIntervalSince1970)",
                        kind: kind,
                        date: payDate,
                        isSpecial: false,
                        specialTitle: nil
                    )
                )
            }

            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthCursor) else { break }
            monthCursor = nextMonth
        }

        for special in specialPays {
            let payDate = calendar.startOfDay(for: special.date)
            guard payDate >= today, payDate <= rangeEnd else { continue }
            events.append(
                PayCalendarEvent(
                    id: "special-\(special.id)",
                    kind: .midMonth,
                    date: payDate,
                    isSpecial: true,
                    specialTitle: special.title
                )
            )
        }

        return events.sorted { $0.date < $1.date }
    }

    static func daysUntil(_ date: Date, from reference: Date = .now, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: reference)
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: target).day ?? 0
    }

    static func payDate(for kind: PayEventKind, in month: Date, calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let year = components.year, let monthValue = components.month else { return nil }

        switch kind {
        case .midMonth:
            let dateComponents = DateComponents(year: year, month: monthValue, day: 15)
            guard let date = calendar.date(from: dateComponents) else { return nil }
            return adjustedPayday(date, calendar: calendar)
        case .monthEnd:
            let dateComponents = DateComponents(year: year, month: monthValue, day: 1)
            guard let date = calendar.date(from: dateComponents) else { return nil }
            return adjustedPayday(date, calendar: calendar)
        }
    }

    /// If the pay date falls on a weekend, move to the prior Friday (common DFAS adjustment).
    static func adjustedPayday(_ date: Date, calendar: Calendar = .current) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: // Sunday
            return calendar.date(byAdding: .day, value: -2, to: date) ?? date
        case 7: // Saturday
            return calendar.date(byAdding: .day, value: -1, to: date) ?? date
        default:
            return calendar.startOfDay(for: date)
        }
    }

    static func gapDays(
        from earlierPay: Date,
        to laterPay: Date,
        calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: earlierPay)
        let end = calendar.startOfDay(for: laterPay)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func payGaps(
        in events: [PayCalendarEvent],
        calendar: Calendar = .current
    ) -> [PayGapInsight] {
        let sorted = events.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return [] }

        return zip(sorted, sorted.dropFirst()).map { prior, next in
            let daysBetween = gapDays(from: prior.date, to: next.date, calendar: calendar)
            return PayGapInsight(
                id: "\(prior.id)-\(next.id)",
                priorPay: prior,
                nextPay: next,
                gapDays: daysBetween
            )
        }
    }

    static func longGapInsights(
        in events: [PayCalendarEvent],
        calendar: Calendar = .current
    ) -> [PayGapInsight] {
        payGaps(in: events, calendar: calendar).filter { $0.gapDays > longGapThresholdDays }
    }

    static func insights(
        from events: [PayCalendarEvent],
        calendar: Calendar = .current,
        limit: Int = 6
    ) -> [PayCalendarInsight] {
        var results: [PayCalendarInsight] = []

        for gap in longGapInsights(in: events, calendar: calendar) {
            results.append(
                PayCalendarInsight(
                    id: "long-\(gap.id)",
                    kind: .longGap,
                    severity: .warning,
                    title: "\(gap.gapDays)-day gap between pays",
                    message: longGapMessage(for: gap, calendar: calendar),
                    relatedDate: gap.nextPay.date
                )
            )
        }

        for gap in payGaps(in: events, calendar: calendar) where gap.gapDays < shortGapThresholdDays {
            results.append(
                PayCalendarInsight(
                    id: "short-\(gap.id)",
                    kind: .shortGap,
                    severity: .info,
                    title: "Pays \(gap.gapDays) days apart",
                    message: shortGapMessage(for: gap, calendar: calendar),
                    relatedDate: gap.nextPay.date
                )
            )
        }

        for event in events where !event.isSpecial && event.kind == .midMonth {
            if let note = weekendAdjustmentInsight(for: event, calendar: calendar) {
                results.append(note)
            }
        }

        return results
            .sorted { $0.relatedDate < $1.relatedDate }
            .prefix(limit)
            .map { $0 }
    }

    static func gapAfter(
        event: PayCalendarEvent,
        in events: [PayCalendarEvent],
        calendar: Calendar = .current
    ) -> PayGapInsight? {
        payGaps(in: events, calendar: calendar).first { $0.priorPay.id == event.id }
    }

    private static func longGapMessage(for gap: PayGapInsight, calendar: Calendar) -> String {
        let prior = formattedPayReference(gap.priorPay, calendar: calendar)
        let next = formattedPayReference(gap.nextPay, calendar: calendar)
        return "\(prior) and \(next) are \(gap.gapDays) days apart — longer than the usual two-week rhythm when the 1st and 15th shift for weekends. Budget for the extra stretch."
    }

    private static func shortGapMessage(for gap: PayGapInsight, calendar: Calendar) -> String {
        let prior = formattedPayReference(gap.priorPay, calendar: calendar)
        let next = formattedPayReference(gap.nextPay, calendar: calendar)
        return "\(prior) and \(next) land close together. You may get two deposits within \(gap.gapDays) days."
    }

    private static func formattedPayReference(_ event: PayCalendarEvent, calendar: Calendar) -> String {
        let dateText = event.date.formatted(.dateTime.month(.abbreviated).day())
        if event.isSpecial {
            return "\(event.title) (\(dateText))"
        }
        return "\(event.kind.title.lowercased()) on \(dateText)"
    }

    private static func weekendAdjustmentInsight(
        for event: PayCalendarEvent,
        calendar: Calendar
    ) -> PayCalendarInsight? {
        guard let nominal = nominalPayDate(for: event.kind, on: event.date, calendar: calendar) else {
            return nil
        }
        let adjusted = calendar.startOfDay(for: event.date)
        guard calendar.startOfDay(for: nominal) != adjusted else { return nil }

        let nominalDay = calendar.component(.day, from: nominal)
        let nominalWeekday = calendar.weekdaySymbols[calendar.component(.weekday, from: nominal) - 1]
        let adjustedText = event.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())

        return PayCalendarInsight(
            id: "weekend-\(event.id)",
            kind: .weekendAdjustment,
            severity: .info,
            title: "\(event.kind.title) moved for weekend",
            message: "Scheduled for \(nominalWeekday) the \(ordinal(nominalDay)), but pays \(adjustedText) instead.",
            relatedDate: event.date
        )
    }

    private static func nominalPayDate(
        for kind: PayEventKind,
        on adjustedDate: Date,
        calendar: Calendar
    ) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: adjustedDate)
        guard let year = components.year, let month = components.month else { return nil }
        let day = kind == .midMonth ? 15 : 1
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func ordinal(_ day: Int) -> String {
        let suffix: String
        let ones = day % 10
        let tens = (day / 10) % 10
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(day)\(suffix)"
    }
}

struct PayGapInsight: Identifiable, Equatable, Sendable {
    let id: String
    let priorPay: PayCalendarEvent
    let nextPay: PayCalendarEvent
    let gapDays: Int

    var isLongGap: Bool {
        gapDays > PayCalendar.longGapThresholdDays
    }

    var isShortGap: Bool {
        gapDays < PayCalendar.shortGapThresholdDays
    }
}

enum PayInsightSeverity: Equatable, Sendable {
    case info
    case warning
}

enum PayCalendarInsightKind: Equatable, Sendable {
    case longGap
    case shortGap
    case weekendAdjustment
}

struct PayCalendarInsight: Identifiable, Equatable, Sendable {
    let id: String
    let kind: PayCalendarInsightKind
    let severity: PayInsightSeverity
    let title: String
    let message: String
    let relatedDate: Date
}
