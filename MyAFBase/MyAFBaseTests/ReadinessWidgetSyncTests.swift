import Foundation
import Testing
@testable import MyAFBase

struct ReadinessWidgetSyncTests {
  @Test func countdownSnapshotForFitnessDueDate() {
    let tracker = ReadinessTracker(
      baseID: "eglin",
      fitnessTestDue: Calendar.current.date(byAdding: .day, value: 10, to: .now)
    )

    let snapshot = ReadinessCountdownBuilder.snapshot(from: tracker, baseName: "Eglin AFB")
    let fitness = snapshot.item(for: .fitness)

    #expect(fitness?.countdownValue == 10)
    #expect(fitness?.countdownLabel == "days")
    #expect(fitness?.title == "PT test")
  }

  @Test func pcsWindowOpenUsesDaysLeftLabel() {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: .now)
    let end = calendar.date(byAdding: .day, value: 5, to: start)
    let tracker = ReadinessTracker(
      baseID: "eglin",
      pcsWindowStart: start,
      pcsWindowEnd: end
    )

    let item = ReadinessCountdownBuilder.buildItem(.pcsWindow, tracker: tracker)
    #expect(item.statusRaw == "windowOpen")
    #expect(item.countdownValue == 5)
  }
}
