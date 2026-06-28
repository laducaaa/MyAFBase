import Foundation
import Testing
@testable import MyAFBase

struct ReadinessStatusTests {
  @Test func overdueWhenPastDue() {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    #expect(ReadinessStatus.evaluate(dueDate: yesterday) == .overdue)
  }

  @Test func dueSoonWithinThirtyDays() {
    let soon = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
    #expect(ReadinessStatus.evaluate(dueDate: soon) == .dueSoon)
  }

  @Test func onTrackBeyondThirtyDays() {
    let later = Calendar.current.date(byAdding: .day, value: 45, to: Date())!
    #expect(ReadinessStatus.evaluate(dueDate: later) == .onTrack)
  }

  @Test func notSetWhenMissingDate() {
    #expect(ReadinessStatus.evaluate(dueDate: nil) == .notSet)
  }

  @Test func pcsWindowOpenWhenInsideRange() {
    let start = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    let end = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
    #expect(ReadinessStatus.evaluatePCSWindow(start: start, end: end) == .windowOpen)
  }
}
