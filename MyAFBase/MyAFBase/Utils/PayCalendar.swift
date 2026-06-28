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
        if isSpecial { "star.circle.fill" }
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
            var dateComponents = DateComponents(year: year, month: monthValue, day: 15)
            guard let date = calendar.date(from: dateComponents) else { return nil }
            return adjustedPayday(date, calendar: calendar)
        case .monthEnd:
            var dateComponents = DateComponents(year: year, month: monthValue, day: 1)
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
}
