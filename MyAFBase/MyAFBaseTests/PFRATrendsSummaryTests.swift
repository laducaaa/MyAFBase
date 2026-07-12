import Foundation
import Testing
@testable import MyAFBase

struct PFRATrendsSummaryTests {
    @Test func emptyTrendsHaveNoAverages() {
        let trends = PFRATrendsSummary(records: [])
        #expect(trends.recordCount == 0)
        #expect(trends.latestScore == nil)
        #expect(trends.averageScore == nil)
        #expect(trends.deltaFromPrevious == nil)
        #expect(trends.chronologicalScores.isEmpty)
    }
}
