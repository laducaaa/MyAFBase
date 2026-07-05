import Foundation
import Testing
@testable import MyAFBase

struct WAROutputBuilderTests {

    @Test func chronologicalPlainTextIncludesAllFields() {
        let entry = WAREntry(
            baseID: "keesler",
            date: Date(timeIntervalSince1970: 0),
            text: "Led base 5K",
            category: .leadership,
            performanceFactor: .leadingPeople,
            tags: ["flightline"],
            impact: "Raised $500",
            beneficiary: "Airman's Attic",
            hours: 4,
            memberType: .enlisted
        )

        let text = WAROutputBuilder.build(entries: [entry], grouping: .chronological, format: .plainText)
        #expect(text.contains("Led base 5K"))
        #expect(text.contains("Impact: Raised $500"))
        #expect(text.contains("Benefited: Airman's Attic"))
        #expect(text.contains("Hours: 4h"))
        #expect(text.contains("#flightline"))
    }

    @Test func draftBulletsAreCondensed() {
        let entry = WAREntry(
            baseID: "keesler",
            date: Date(timeIntervalSince1970: 0),
            text: "Organized fundraiser",
            category: .volunteer,
            performanceFactor: nil,
            tags: [],
            impact: "Raised $2,400",
            beneficiary: nil,
            hours: nil,
            memberType: .enlisted
        )

        let text = WAROutputBuilder.build(entries: [entry], grouping: .chronological, format: .draftBullets)
        #expect(text.hasPrefix("- "))
        #expect(text.contains("Organized fundraiser; Raised $2,400"))
    }

    @Test func groupedByCategorySeparatesSections() {
        let jobEntry = WAREntry(baseID: "keesler", date: .now, text: "Job task", category: .job, memberType: .enlisted)
        let volunteerEntry = WAREntry(baseID: "keesler", date: .now, text: "Volunteer task", category: .volunteer, memberType: .enlisted)

        let text = WAROutputBuilder.build(entries: [jobEntry, volunteerEntry], grouping: .category, format: .plainText)
        #expect(text.contains("JOB"))
        #expect(text.contains("VOLUNTEER"))
    }

    @Test func emptyEntriesProducesPlaceholderMessage() {
        let text = WAROutputBuilder.build(entries: [], grouping: .chronological, format: .plainText)
        #expect(text.contains("No entries"))
    }

    @Test func summaryComputesTotalsAndBreakdowns() {
        let entryOne = WAREntry(baseID: "keesler", date: .now, text: "A", category: .job, performanceFactor: .executingTheMission, hours: 2, memberType: .enlisted)
        let entryTwo = WAREntry(baseID: "keesler", date: .now, text: "B", category: .job, performanceFactor: .executingTheMission, hours: 3, memberType: .enlisted)
        let entryThree = WAREntry(baseID: "keesler", date: .now, text: "C", category: .volunteer, memberType: .enlisted)

        let summary = WAROutputBuilder.summary(for: [entryOne, entryTwo, entryThree])
        #expect(summary.totalEntries == 3)
        #expect(summary.totalHours == 5)
        #expect(summary.categoryCounts.first?.category == .job)
        #expect(summary.categoryCounts.first?.count == 2)
        #expect(summary.factorCounts.first?.count == 2)
    }

    @Test func nominationDraftIncludesAwardAndBullets() {
        let entry = WAREntry(baseID: "keesler", date: .now, text: "Mentored 3 Airmen", category: .leadership, memberType: .enlisted)
        let draft = WAROutputBuilder.nominationDraft(
            entries: [entry],
            awardName: "NCO of the Quarter",
            tone: .standard,
            level: .squadron,
            memberType: .enlisted
        )
        #expect(draft.contains("NCO of the Quarter"))
        #expect(draft.contains("Mentored 3 Airmen"))
    }
}
