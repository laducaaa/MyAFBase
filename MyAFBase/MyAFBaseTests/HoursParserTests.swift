import Foundation
import Testing
@testable import MyAFBase

struct HoursParserTests {
    @Test func parsesDailyHours() {
        let parsed = HoursParser.parse("Daily 0800-1900")
        #expect(parsed.isStructured)
        #expect(parsed.rows.count == 7)
        #expect(parsed.groupedRows.count == 1)
        #expect(parsed.groupedRows.first?.dayLabel == "Every day")
    }

    @Test func parsesWeekdayRange() {
        let parsed = HoursParser.parse("Mon-Fri 0900-1700")
        #expect(parsed.isStructured)
        #expect(parsed.rows.count == 5)
        #expect(parsed.groupedRows.count == 1)
        #expect(parsed.groupedRows.first?.dayLabel == "Mon – Fri")
    }

    @Test func parsesSplitSchedule() {
        let parsed = HoursParser.parse("Mon-Sat 0900-2000; Sun 1000-1800")
        #expect(parsed.isStructured)
        #expect(parsed.rows.count == 7)
        #expect(parsed.groupedRows.count == 2)
        #expect(parsed.groupedRows.contains { $0.dayLabel == "Sunday" })
        #expect(parsed.groupedRows.contains { $0.dayLabel == "Mon – Sat" })
    }

    @Test func detectsAlwaysOpen() {
        let parsed = HoursParser.parse("Open 24/7")
        #expect(parsed.status == .alwaysOpen)
        #expect(parsed.todayHoursText == "Open 24 hours")
        #expect(!parsed.isStructured)
    }

    @Test func fallsBackForUnstructuredHours() {
        let parsed = HoursParser.parse("See posted hours at facility")
        #expect(parsed.fallbackText == "See posted hours at facility")
        #expect(!parsed.isStructured)
    }

    @Test func formatsMultiMealSegment() {
        let parsed = HoursParser.parse("Mon-Fri: Breakfast 0600-0800, Lunch 1100-1300, Dinner 1700-1900")
        #expect(parsed.isStructured)
        #expect(parsed.groupedRows.count == 1)
        let hours = parsed.groupedRows.first?.hoursText
        #expect(hours?.contains("6:00 AM") == true)
        #expect(hours?.contains("Breakfast") == true)
    }

    @Test func parsesClosedDays() {
        let parsed = HoursParser.parse("Mon-Fri: Bfast 0600-0900, Lunch 1030-1330; Sat-Sun closed")
        #expect(parsed.isStructured)
        #expect(parsed.groupedRows.count == 3)
        #expect(parsed.groupedRows.contains { $0.hoursText == "Closed" })
        #expect(parsed.groupedRows.contains { $0.dayLabel == "Mon – Fri" })
    }

    @Test func parsesMealPrefixedHours() {
        let parsed = HoursParser.parse(
            "Breakfast Mon-Fri 0515-0800; Lunch Mon-Fri 1100-1330; Dinner Mon-Fri 1830-2030. Flight Kitchen daily 0600-2200."
        )
        #expect(parsed.mealEntries.count == 4)
        #expect(parsed.isStructured)
        #expect(parsed.mealEntries.contains { $0.name == "Breakfast" })
        #expect(parsed.mealEntries.contains { $0.name == "Flight Kitchen" })
    }

    @Test func cardDisplayForMealHours() {
        let wednesday = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 24))!
        let display = HoursParser.cardDisplay(
            for: "Breakfast Mon-Fri 0515-0800; Lunch Mon-Fri 1100-1330; Dinner Mon-Fri 1830-2030. Flight Kitchen daily 0600-2200.",
            maxLines: 4,
            now: wednesday
        )

        #expect(display.lines.count == 4)
        #expect(display.lines.first?.label == "Breakfast")
        #expect(display.lines.first?.value.contains("5:15 AM") == true)
        #expect(!display.hasMore)
    }
}
