import Foundation
import SwiftData
import Testing
@testable import MyAFBase

@MainActor
struct WARTrackerStoreTests {

    @Test func addEntryPersistsFields() throws {
        let container = try makeContainer()
        let store = WARTrackerStore(modelContext: container.mainContext)

        let entry = store.addEntry(
            baseID: "keesler",
            date: .now,
            text: "Organized base 5K fundraiser",
            category: .volunteer,
            performanceFactor: .leadingPeople,
            tags: ["#Flightline", " innovation ", "flightline"],
            impact: "Raised $2,400",
            beneficiary: "Airman's Attic",
            hours: 6,
            memberType: .enlisted
        )

        #expect(entry.text == "Organized base 5K fundraiser")
        #expect(entry.category == .volunteer)
        #expect(entry.performanceFactor == .leadingPeople)
        // Tags are normalized: lowercased, "#" stripped, de-duplicated.
        #expect(entry.tags == ["flightline", "innovation"])
        #expect(entry.impact == "Raised $2,400")
        #expect(entry.hours == 6)
    }

    @Test func entriesFilteredByBaseAndDay() throws {
        let container = try makeContainer()
        let store = WARTrackerStore(modelContext: container.mainContext)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        store.addEntry(
            baseID: "keesler", date: today, text: "Today entry", category: .job,
            performanceFactor: nil, tags: [], impact: nil, beneficiary: nil, hours: nil,
            memberType: .enlisted
        )
        store.addEntry(
            baseID: "keesler", date: yesterday, text: "Yesterday entry", category: .job,
            performanceFactor: nil, tags: [], impact: nil, beneficiary: nil, hours: nil,
            memberType: .enlisted
        )
        store.addEntry(
            baseID: "eglin", date: today, text: "Other base entry", category: .job,
            performanceFactor: nil, tags: [], impact: nil, beneficiary: nil, hours: nil,
            memberType: .enlisted
        )

        let todayEntries = store.entries(for: "keesler", on: today)
        #expect(todayEntries.count == 1)
        #expect(todayEntries.first?.text == "Today entry")
    }

    @Test func updateEntryOverwritesFields() throws {
        let container = try makeContainer()
        let store = WARTrackerStore(modelContext: container.mainContext)

        let entry = store.addEntry(
            baseID: "keesler", date: .now, text: "Draft", category: .job,
            performanceFactor: nil, tags: [], impact: nil, beneficiary: nil, hours: nil,
            memberType: .enlisted
        )

        store.update(
            entry,
            date: entry.date,
            text: "Finalized bullet",
            category: .leadership,
            performanceFactor: .improvingTheUnit,
            tags: ["mentorship"],
            impact: "Improved onboarding",
            beneficiary: "New Airmen",
            hours: 2
        )

        #expect(entry.text == "Finalized bullet")
        #expect(entry.category == .leadership)
        #expect(entry.performanceFactor == .improvingTheUnit)
        #expect(entry.tags == ["mentorship"])
    }

    @Test func deleteEntryRemovesIt() throws {
        let container = try makeContainer()
        let store = WARTrackerStore(modelContext: container.mainContext)

        let entry = store.addEntry(
            baseID: "keesler", date: .now, text: "Temp", category: .job,
            performanceFactor: nil, tags: [], impact: nil, beneficiary: nil, hours: nil,
            memberType: .enlisted
        )
        #expect(store.allEntries(for: "keesler").count == 1)

        store.delete(entry)
        #expect(store.allEntries(for: "keesler").isEmpty)
    }

    @Test func suggestedTagsSortedByFrequency() throws {
        let container = try makeContainer()
        let store = WARTrackerStore(modelContext: container.mainContext)

        for _ in 0..<3 {
            store.addEntry(
                baseID: "keesler", date: .now, text: "Entry", category: .job,
                performanceFactor: nil, tags: ["flightline"], impact: nil, beneficiary: nil, hours: nil,
                memberType: .enlisted
            )
        }
        store.addEntry(
            baseID: "keesler", date: .now, text: "Entry", category: .job,
            performanceFactor: nil, tags: ["innovation"], impact: nil, beneficiary: nil, hours: nil,
            memberType: .enlisted
        )

        let suggestions = store.suggestedTags(for: "keesler")
        #expect(suggestions.first == "flightline")
        #expect(suggestions.contains("innovation"))
    }

    @Test func deadlineCRUDRoundTrips() throws {
        let container = try makeContainer()
        let store = WARTrackerStore(modelContext: container.mainContext)

        let dueDate = Calendar.current.date(byAdding: .day, value: 10, to: .now)!
        let deadline = store.addDeadline(baseID: "keesler", title: "Quarterly Award", dueDate: dueDate, notes: "Draft due first")
        #expect(store.deadlines(for: "keesler").count == 1)
        #expect(deadline.daysUntilDue == 10)
        #expect(!deadline.isPastDue)

        store.updateDeadline(deadline, title: "Quarterly Award Package", dueDate: dueDate, notes: nil)
        #expect(deadline.title == "Quarterly Award Package")
        #expect(deadline.notes == nil)

        store.deleteDeadline(deadline)
        #expect(store.deadlines(for: "keesler").isEmpty)
    }

    @Test func upcomingDeadlinesExcludesPastDue() throws {
        let container = try makeContainer()
        let store = WARTrackerStore(modelContext: container.mainContext)
        let past = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        let future = Calendar.current.date(byAdding: .day, value: 5, to: .now)!

        store.addDeadline(baseID: "keesler", title: "Past Due", dueDate: past, notes: nil)
        store.addDeadline(baseID: "keesler", title: "Upcoming", dueDate: future, notes: nil)

        let upcoming = store.upcomingDeadlines(for: "keesler")
        #expect(upcoming.count == 1)
        #expect(upcoming.first?.title == "Upcoming")
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([WAREntry.self, WARAwardDeadline.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
