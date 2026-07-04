import Foundation
import Testing
@testable import MyAFBase

struct PayCalendarTests {
  @Test func midMonthPayAdjustsFromSundayToFriday() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    // June 2026: 15th is a Monday — no adjustment
    let june = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
    let midJune = PayCalendar.payDate(for: .midMonth, in: june, calendar: calendar)
    #expect(calendar.component(.day, from: midJune!) == 15)

    // November 2026: 15th is a Sunday -> Friday the 13th
    let november = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
    let midNovember = PayCalendar.payDate(for: .midMonth, in: november, calendar: calendar)
    #expect(calendar.component(.day, from: midNovember!) == 13)
    #expect(calendar.component(.weekday, from: midNovember!) == 6)
  }

  @Test func upcomingEventsIncludeSpecialPays() {
    let calendar = Calendar.current
    let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
    let special = SpecialPayEntry(
      title: "Assignment Incentive Pay",
      date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 10))!
    )

    let events = PayCalendar.upcomingEvents(from: start, monthsAhead: 3, specialPays: [special], calendar: calendar)
    #expect(events.contains { $0.isSpecial && $0.title == "Assignment Incentive Pay" })
  }

  @Test func detectsLongGapAfterWeekendAdjustedMidMonthPay() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
    let events = PayCalendar.upcomingEvents(from: start, monthsAhead: 3, calendar: calendar)
    let longGaps = PayCalendar.longGapInsights(in: events, calendar: calendar)

    let novemberGap = longGaps.first {
      calendar.component(.month, from: $0.priorPay.date) == 11
        && calendar.component(.month, from: $0.nextPay.date) == 12
    }

    #expect(novemberGap != nil)
    #expect(novemberGap?.gapDays ?? 0 > PayCalendar.longGapThresholdDays)
  }

  @Test func insightsIncludeLongGapWarning() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
    let events = PayCalendar.upcomingEvents(from: start, monthsAhead: 3, calendar: calendar)
    let insights = PayCalendar.insights(from: events, calendar: calendar)

    #expect(insights.contains { $0.kind == .longGap && $0.severity == .warning })
  }
}

struct EmergencyWidgetBuilderTests {
  @Test func prioritizes911SecurityAndHospital() async {
    let service = LocalJSONDataService()
    guard let base = await service.loadBase(id: "eglin") else {
      Issue.record("Expected eglin base fixture")
      return
    }

    let snapshot = EmergencyWidgetBuilder.snapshot(from: base)
    #expect(snapshot.contacts.first?.isUniversalEmergency == true)
    #expect(snapshot.contacts.contains { $0.label.localizedCaseInsensitiveContains("security") })
    #expect(snapshot.contacts.contains { $0.label.localizedCaseInsensitiveContains("hospital") })
  }
}
