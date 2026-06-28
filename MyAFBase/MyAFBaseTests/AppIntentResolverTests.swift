import Foundation
import Testing
@testable import MyAFBase

struct AppIntentPayResolverTests {
    @Test
    func spokenSummaryDescribesUpcomingPay() {
        let snapshot = PayWidgetSnapshot(
            nextTitle: "Mid-month pay",
            nextDate: Date(timeIntervalSince1970: 1_700_000_000),
            daysUntil: 3,
            isSpecial: false,
            symbolName: "dollarsign.circle",
            upcoming: [],
            updatedAt: .now
        )

        let spoken = AppIntentPayResolver.spokenSummary(from: snapshot)
        #expect(spoken.contains("Mid-month pay"))
        #expect(spoken.contains("3 days"))
    }

    @Test
    func spokenSummaryHandlesMissingPayData() {
        let snapshot = PayWidgetSnapshot(
            nextTitle: "",
            nextDate: .now,
            daysUntil: 0,
            isSpecial: false,
            symbolName: "dollarsign.circle",
            upcoming: [],
            updatedAt: .now
        )

        let spoken = AppIntentPayResolver.spokenSummary(from: snapshot)
        #expect(spoken.contains("No upcoming pay date"))
    }
}

struct AppIntentReminderResolverTests {
    @Test
    func spokenSummaryUsesReminderTitleAndSubtitle() {
        let reminder = ReadinessReminder(
            id: "readiness-dental-2026-06-01",
            kind: .dental,
            title: "Dental",
            subtitle: "Due in 5 days",
            detail: "Jun 1, 2026",
            status: .dueSoon,
            systemImage: "mouth.fill",
            sortPriority: 10_005,
            countdownValue: 5,
            countdownUnit: "days"
        )

        let spoken = AppIntentReminderResolver.spokenSummary(for: reminder)
        #expect(spoken == "Dental. Due in 5 days")
    }
}
