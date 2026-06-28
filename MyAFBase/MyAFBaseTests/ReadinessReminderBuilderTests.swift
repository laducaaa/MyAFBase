import Foundation
import Testing
@testable import MyAFBase

struct ReadinessReminderBuilderTests {
    @Test func buildsDentalReminderWithCountdown() throws {
        let dueDate = try #require(Calendar.current.date(byAdding: .day, value: 20, to: .now))
        let tracker = ReadinessTracker(baseID: "keesler", dentalDue: dueDate)

        let reminders = ReadinessReminderBuilder.reminders(from: tracker)
        let dental = try #require(reminders.first { $0.kind == .dental })

        #expect(dental.subtitle == "Due in 20 days")
        #expect(dental.title == "Dental")
        #expect(dental.status == .dueSoon)
    }

    @Test func excludesUnsetItems() {
        let tracker = ReadinessTracker(baseID: "keesler")

        let reminders = ReadinessReminderBuilder.reminders(from: tracker)
        #expect(reminders.isEmpty)
    }

    @Test func sortsOverdueBeforeUpcoming() throws {
        let calendar = Calendar.current
        let overdue = try #require(calendar.date(byAdding: .day, value: -2, to: .now))
        let upcoming = try #require(calendar.date(byAdding: .day, value: 30, to: .now))
        let tracker = ReadinessTracker(
            baseID: "keesler",
            fitnessTestDue: upcoming,
            dentalDue: overdue
        )

        let reminders = ReadinessReminderBuilder.reminders(from: tracker)
        #expect(reminders.count == 2)
        #expect(reminders.first?.kind == .dental)
    }

    @Test func dismissalIDChangesWhenDueDateChanges() throws {
        let calendar = Calendar.current
        let firstDate = try #require(calendar.date(byAdding: .day, value: 20, to: .now))
        let secondDate = try #require(calendar.date(byAdding: .day, value: 25, to: .now))

        let tracker = ReadinessTracker(baseID: "keesler", dentalDue: firstDate)
        let firstID = try #require(ReadinessReminder.dismissalID(kind: .dental, tracker: tracker))

        tracker.dentalDue = secondDate
        let secondID = try #require(ReadinessReminder.dismissalID(kind: .dental, tracker: tracker))

        #expect(firstID != secondID)
    }
}
