import Foundation

struct DayHoursRow: Identifiable, Equatable {
    let weekday: Int
    let hoursText: String
    let isToday: Bool

    var id: Int { weekday }

    var dayName: String {
        HoursParser.weekdayNames[weekday] ?? ""
    }

    var shortDayName: String {
        HoursParser.shortWeekdayNames[weekday] ?? dayName
    }
}

struct GroupedDayHoursRow: Identifiable, Equatable {
    let dayLabel: String
    let hoursText: String
    let includesToday: Bool

    var id: String { "\(dayLabel)-\(hoursText)" }
}

struct MealHoursEntry: Identifiable, Equatable {
    let name: String
    let dayLabel: String
    let days: [Int]
    let hoursText: String

    var id: String { name }

    func applies(to weekday: Int) -> Bool {
        days.contains(weekday)
    }
}

struct HoursCardLine: Identifiable, Equatable {
    let label: String
    let value: String

    var id: String { "\(label)-\(value)" }
}

struct HoursCardDisplay: Equatable {
    let lines: [HoursCardLine]
    let hasMore: Bool
}

enum OpenStatus: Equatable {
    case open
    case closed
    case alwaysOpen
}

struct ParsedHours: Equatable {
    let rows: [DayHoursRow]
    let groupedRows: [GroupedDayHoursRow]
    let mealEntries: [MealHoursEntry]
    let status: OpenStatus?
    let todayHoursText: String?
    let fallbackText: String?

    var isStructured: Bool {
        !rows.isEmpty || !mealEntries.isEmpty
    }
}

enum HoursParser {
    static let weekdayNames = [
        1: "Sunday",
        2: "Monday",
        3: "Tuesday",
        4: "Wednesday",
        5: "Thursday",
        6: "Friday",
        7: "Saturday"
    ]

    static let shortWeekdayNames = [
        1: "Sun",
        2: "Mon",
        3: "Tue",
        4: "Wed",
        5: "Thu",
        6: "Fri",
        7: "Sat"
    ]

    private static let mapsDisplayOrder = [1, 2, 3, 4, 5, 6, 7]

    static func parse(_ raw: String, now: Date = Date(), calendar: Calendar = .current) -> ParsedHours {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return emptyParsedHours()
        }

        let lower = trimmed.lowercased()
        if lower.contains("24/7") || lower.contains("24 hours") || lower.contains("open 24") {
            return ParsedHours(
                rows: [],
                groupedRows: [],
                mealEntries: [],
                status: .alwaysOpen,
                todayHoursText: "Open 24 hours",
                fallbackText: nil
            )
        }

        if isUnstructured(trimmed) {
            return ParsedHours(
                rows: [],
                groupedRows: [],
                mealEntries: [],
                status: nil,
                todayHoursText: nil,
                fallbackText: trimmed
            )
        }

        let segments = splitSegments(trimmed)
        var schedule = Array(repeating: "", count: 8)
        var mealEntries: [MealHoursEntry] = []

        for segment in segments where !segment.isEmpty {
            if let meal = parseMealSegment(segment) {
                mealEntries.append(meal)
                let formattedHours = formatHoursText(meal.hoursText)
                for day in meal.days where schedule[day].isEmpty {
                    schedule[day] = formattedHours
                }
                continue
            }

            guard let parsed = parseSegment(segment) else { continue }
            for day in parsed.days where schedule[day].isEmpty {
                schedule[day] = formatHoursText(parsed.hoursText)
            }
        }

        let today = calendar.component(.weekday, from: now)

        if !mealEntries.isEmpty {
            let status = openStatusForMeals(mealEntries, weekday: today, now: now, calendar: calendar)
            let todaysMeals = mealEntries.filter { $0.applies(to: today) }

            return ParsedHours(
                rows: [],
                groupedRows: [],
                mealEntries: mealEntries,
                status: status,
                todayHoursText: todaysMeals.isEmpty ? "Closed today" : nil,
                fallbackText: nil
            )
        }

        let hasSchedule = schedule.dropFirst().contains { !$0.isEmpty }
        guard hasSchedule else {
            return ParsedHours(
                rows: [],
                groupedRows: [],
                mealEntries: [],
                status: nil,
                todayHoursText: nil,
                fallbackText: trimmed
            )
        }

        let rows = mapsDisplayOrder.compactMap { day -> DayHoursRow? in
            let hours = schedule[day]
            guard !hours.isEmpty else { return nil }
            return DayHoursRow(weekday: day, hoursText: hours, isToday: day == today)
        }

        let groupedRows = groupRows(rows)
        let todayHours = schedule[today]
        let status = openStatus(for: todayHours, now: now, calendar: calendar)

        return ParsedHours(
            rows: rows,
            groupedRows: groupedRows,
            mealEntries: [],
            status: status,
            todayHoursText: summaryHours(for: todayHours) ?? displayHours(todayHours),
            fallbackText: nil
        )
    }

    static func cardDisplay(
        for raw: String,
        maxLines: Int = 4,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> HoursCardDisplay {
        let parsed = parse(raw, now: now, calendar: calendar)
        let today = calendar.component(.weekday, from: now)

        if parsed.status == .alwaysOpen {
            return HoursCardDisplay(
                lines: [HoursCardLine(label: "", value: "Open 24 hours")],
                hasMore: false
            )
        }

        if !parsed.mealEntries.isEmpty {
            let todaysMeals = parsed.mealEntries.filter { $0.applies(to: today) }
            let visible = todaysMeals.prefix(maxLines)
            let lines = visible.map { entry in
                HoursCardLine(
                    label: entry.name,
                    value: summaryHours(for: entry.hoursText) ?? formatHoursText(entry.hoursText)
                )
            }
            return HoursCardDisplay(
                lines: Array(lines),
                hasMore: todaysMeals.count > maxLines
            )
        }

        if parsed.isStructured {
            if let todayRow = parsed.groupedRows.first(where: \.includesToday) {
                return HoursCardDisplay(
                    lines: [HoursCardLine(label: "Today", value: todayRow.hoursText)],
                    hasMore: parsed.groupedRows.count > 1
                )
            }

            if let todayHours = parsed.todayHoursText {
                return HoursCardDisplay(
                    lines: [HoursCardLine(label: "Today", value: todayHours)],
                    hasMore: parsed.groupedRows.count > 1
                )
            }
        }

        if let fallback = parsed.fallbackText {
            return fallbackCardDisplay(fallback, maxLines: maxLines)
        }

        return HoursCardDisplay(lines: [], hasMore: false)
    }

    static func summaryHours(for hoursText: String?) -> String? {
        guard let hoursText, !hoursText.isEmpty else { return nil }
        if hoursText.compare("closed", options: .caseInsensitive) == .orderedSame {
            return "Closed"
        }

        let ranges = timeRanges(in: hoursText)
        guard let first = ranges.first, let last = ranges.last else {
            return displayHours(hoursText)
        }

        if ranges.count == 1 {
            return "\(formatClockTime(first.open)) – \(formatClockTime(first.close))"
        }

        return "\(formatClockTime(first.open)) – \(formatClockTime(last.close))"
    }

    static func groupRows(_ rows: [DayHoursRow]) -> [GroupedDayHoursRow] {
        guard !rows.isEmpty else { return [] }

        var groups: [GroupedDayHoursRow] = []
        var index = 0

        while index < rows.count {
            let start = rows[index]
            var endIndex = index

            while endIndex + 1 < rows.count,
                  rows[endIndex + 1].hoursText.caseInsensitiveCompare(start.hoursText) == .orderedSame,
                  rows[endIndex + 1].weekday == rows[endIndex].weekday + 1 {
                endIndex += 1
            }

            let slice = rows[index...endIndex]
            let includesToday = slice.contains(where: \.isToday)
            let label = groupLabel(for: slice)
            groups.append(
                GroupedDayHoursRow(
                    dayLabel: label,
                    hoursText: displayHours(start.hoursText) ?? start.hoursText,
                    includesToday: includesToday
                )
            )
            index = endIndex + 1
        }

        return groups
    }

    private static func groupLabel(for rows: ArraySlice<DayHoursRow>) -> String {
        guard let first = rows.first else { return "" }
        guard let last = rows.last, rows.count > 1 else { return first.dayName }

        if rows.count == 7 {
            return "Every day"
        }

        return "\(first.shortDayName) – \(last.shortDayName)"
    }

    private static func displayHours(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        if text.compare("closed", options: .caseInsensitive) == .orderedSame {
            return "Closed"
        }
        return text
    }

    private static func isUnstructured(_ text: String) -> Bool {
        let lower = text.lowercased()
        let markers = [
            "see posted",
            "see fss",
            "contact facility",
            "contact ",
            "call to verify",
            "varies by",
            "business hours",
            "duty hours",
            "during duty",
            "appointment",
            "seasonal"
        ]
        return markers.contains { lower.contains($0) }
    }

    private struct SegmentParse {
        let days: [Int]
        let hoursText: String
    }

    private static func parseSegment(_ segment: String) -> SegmentParse? {
        let pattern = #"^(Daily|Sun|Mon|Tue|Wed|Thu|Fri|Sat)(?:-(Sun|Mon|Tue|Wed|Thu|Fri|Sat))?\s*:?\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: segment, range: NSRange(segment.startIndex..., in: segment)),
              let hoursRange = Range(match.range(at: 3), in: segment) else {
            return nil
        }

        let startToken = String(segment[Range(match.range(at: 1), in: segment)!])
        let endToken = match.range(at: 2).location != NSNotFound
            ? String(segment[Range(match.range(at: 2), in: segment)!])
            : nil
        let hoursText = String(segment[hoursRange])

        let days = expandDays(start: startToken, end: endToken)
        guard !days.isEmpty else { return nil }
        return SegmentParse(days: days, hoursText: hoursText)
    }

    private static func expandDays(start: String, end: String?) -> [Int] {
        if start.caseInsensitiveCompare("Daily") == .orderedSame {
            return Array(1...7)
        }

        guard let startDay = dayIndex(for: start) else { return [] }
        guard let end, let endDay = dayIndex(for: end) else { return [startDay] }

        if startDay <= endDay {
            return Array(startDay...endDay)
        }
        return Array(startDay...7) + Array(1...endDay)
    }

    private static func dayIndex(for token: String) -> Int? {
        switch token.lowercased().prefix(3) {
        case "sun": return 1
        case "mon": return 2
        case "tue": return 3
        case "wed": return 4
        case "thu": return 5
        case "fri": return 6
        case "sat": return 7
        default: return nil
        }
    }

    private static func formatHoursText(_ text: String) -> String {
        let pattern = #"\b(\d{3,4})\s*[-–]\s*(\d{3,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return text }

        var result = text
        for match in matches.reversed() {
            guard let range = Range(match.range, in: result),
                  let startRange = Range(match.range(at: 1), in: result),
                  let endRange = Range(match.range(at: 2), in: result),
                  let start = militaryTime(String(result[startRange])),
                  let end = militaryTime(String(result[endRange])) else { continue }
            result.replaceSubrange(range, with: "\(start) – \(end)")
        }
        return result
    }

    private static func emptyParsedHours() -> ParsedHours {
        ParsedHours(
            rows: [],
            groupedRows: [],
            mealEntries: [],
            status: nil,
            todayHoursText: nil,
            fallbackText: nil
        )
    }

    private static func splitSegments(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == ";" || $0 == "." })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func parseMealSegment(_ segment: String) -> MealHoursEntry? {
        let pattern = #"^(Breakfast|Lunch|Dinner|Bfast|Brunch|Flight Kitchen)\s+(Daily|Sun|Mon|Tue|Wed|Thu|Fri|Sat)(?:-(Sun|Mon|Tue|Wed|Thu|Fri|Sat))?\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: segment, range: NSRange(segment.startIndex..., in: segment)),
              let hoursRange = Range(match.range(at: 4), in: segment) else {
            return nil
        }

        let mealName = String(segment[Range(match.range(at: 1), in: segment)!])
        let startToken = String(segment[Range(match.range(at: 2), in: segment)!])
        let endToken = match.range(at: 3).location != NSNotFound
            ? String(segment[Range(match.range(at: 3), in: segment)!])
            : nil
        let hoursText = String(segment[hoursRange])
        let days = expandDays(start: startToken, end: endToken)
        guard !days.isEmpty else { return nil }

        return MealHoursEntry(
            name: mealName,
            dayLabel: mealDayLabel(for: days),
            days: days,
            hoursText: formatHoursText(hoursText)
        )
    }

    private static func mealDayLabel(for days: [Int]) -> String {
        guard let first = days.first else { return "" }
        guard let last = days.last, days.count > 1 else {
            return shortWeekdayNames[first] ?? weekdayNames[first] ?? ""
        }
        if days.count == 7 {
            return "Every day"
        }
        return "\(shortWeekdayNames[first] ?? "") – \(shortWeekdayNames[last] ?? "")"
    }

    private static func openStatusForMeals(
        _ entries: [MealHoursEntry],
        weekday: Int,
        now: Date,
        calendar: Calendar
    ) -> OpenStatus? {
        let todays = entries.filter { $0.applies(to: weekday) }
        guard !todays.isEmpty else { return .closed }

        var foundRange = false
        for entry in todays {
            let ranges = timeRanges(in: formatHoursText(entry.hoursText))
            if !ranges.isEmpty {
                foundRange = true
            }
            for range in ranges where now >= range.open && now < range.close {
                return .open
            }
        }
        return foundRange ? .closed : nil
    }

    private static func fallbackCardDisplay(_ text: String, maxLines: Int) -> HoursCardDisplay {
        let parts = splitSegments(text)
        if parts.count <= 1 {
            return HoursCardDisplay(
                lines: [HoursCardLine(label: "", value: formatHoursText(text))],
                hasMore: false
            )
        }

        let lines = parts.prefix(maxLines).map { part in
            if let meal = parseMealSegment(part) {
                return HoursCardLine(
                    label: meal.name,
                    value: summaryHours(for: meal.hoursText) ?? formatHoursText(meal.hoursText)
                )
            }
            return HoursCardLine(label: "", value: formatHoursText(part))
        }

        return HoursCardDisplay(lines: Array(lines), hasMore: parts.count > maxLines)
    }

    private static func militaryTime(_ token: String) -> String? {
        let digits = token.filter(\.isNumber)
        guard digits.count == 3 || digits.count == 4, let value = Int(digits) else { return nil }

        let hours = value / 100
        let minutes = value % 100
        guard (0...23).contains(hours), (0...59).contains(minutes) else { return nil }

        var components = DateComponents()
        components.hour = hours
        components.minute = minutes

        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return nil }
        return formatClockTime(date)
    }

    private static func openStatus(
        for hoursText: String?,
        now: Date,
        calendar: Calendar
    ) -> OpenStatus? {
        guard let hoursText, !hoursText.isEmpty else { return nil }
        if hoursText.compare("closed", options: .caseInsensitive) == .orderedSame {
            return .closed
        }

        let ranges = timeRanges(in: hoursText)
        guard !ranges.isEmpty else { return nil }

        for range in ranges where now >= range.open && now < range.close {
            return .open
        }
        return .closed
    }

    private struct TimeRange {
        let open: Date
        let close: Date
    }

    private static func timeRanges(in hoursText: String) -> [TimeRange] {
        let pattern = #"(\d{1,2}:\d{2}\s*(?:AM|PM))\s*[–-]\s*(\d{1,2}:\d{2}\s*(?:AM|PM))"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }

        let nsRange = NSRange(hoursText.startIndex..., in: hoursText)
        let calendar = Calendar.current
        let now = Date()

        return regex.matches(in: hoursText, range: nsRange).compactMap { match in
            guard let openRange = Range(match.range(at: 1), in: hoursText),
                  let closeRange = Range(match.range(at: 2), in: hoursText),
                  let openDate = parseClockTime(String(hoursText[openRange]), on: now, calendar: calendar),
                  let closeDate = parseClockTime(String(hoursText[closeRange]), on: now, calendar: calendar) else {
                return nil
            }
            return TimeRange(open: openDate, close: closeDate)
        }
    }

    private static func formatClockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private static func parseClockTime(_ text: String, on date: Date, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        let cleaned = text.trimmingCharacters(in: .whitespaces)
        guard let time = formatter.date(from: cleaned) else { return nil }

        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dayComponents.hour = timeComponents.hour
        dayComponents.minute = timeComponents.minute
        return calendar.date(from: dayComponents)
    }
}
