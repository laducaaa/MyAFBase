import Foundation
import Testing
@testable import MyAFBase

struct HomeWidgetSyncTests {
  @Test func weatherSnapshotUsesLiveWeatherValues() async {
    let service = LocalJSONDataService()
    guard let base = await service.loadBase(id: "eglin") else {
      Issue.record("Expected eglin base fixture")
      return
    }

    let weather = Weather(
      tempF: 78.4,
      feelsLikeF: 81.2,
      weatherCode: 2,
      windMph: 11.6,
      humidity: 58,
      isDay: true,
      precipitationIn: 0,
      lastUpdated: Date(timeIntervalSince1970: 1_700_000_000),
      observationTime: Date(timeIntervalSince1970: 1_700_000_000)
    )

    let snapshot = WeatherWidgetBuilder.snapshot(from: base, weather: weather)

    #expect(snapshot.baseName == "Eglin AFB")
    #expect(snapshot.tempF == 78)
    #expect(snapshot.feelsLikeF == 81)
    #expect(snapshot.conditionName == "Partly Cloudy")
    #expect(snapshot.windMph == 12)
    #expect(snapshot.isAvailable)
  }

  @Test func weatherSnapshotUnavailableWhenPlaceholder() async {
    let service = LocalJSONDataService()
    guard let base = await service.loadBase(id: "eglin") else {
      Issue.record("Expected eglin base fixture")
      return
    }

    let snapshot = WeatherWidgetBuilder.snapshot(from: base, weather: .placeholder())

    #expect(!snapshot.isAvailable)
    #expect(snapshot.tempF == nil)
    #expect(snapshot.conditionName == "Unavailable")
  }

  @Test func openNowSnapshotIncludesOpenEntries() async {
    let service = LocalJSONDataService()
    guard let base = await service.loadBase(id: "eglin") else {
      Issue.record("Expected eglin base fixture")
      return
    }

    let snapshot = OpenNowWidgetBuilder.snapshot(from: base, savedItems: [])

    #expect(snapshot.baseName == "Eglin AFB")
    #expect(snapshot.items.allSatisfy { !$0.name.isEmpty })
    #expect(snapshot.summaryText.contains("open") || snapshot.openCount == 0)
  }
}
