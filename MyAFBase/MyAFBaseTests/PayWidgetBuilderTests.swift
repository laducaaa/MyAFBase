import Foundation
import Testing
@testable import MyAFBase

struct PayWidgetBuilderTests {

    @Test func snapshotIncludesNextPayAndUpcoming() {
        let snapshot = PayWidgetBuilder.snapshot(from: Date(timeIntervalSince1970: 1_700_000_000))

        #expect(snapshot.isAvailable)
        #expect(!snapshot.upcoming.isEmpty)
        #expect(snapshot.daysUntil >= 0)
        #expect(!snapshot.nextTitle.isEmpty)
    }

    @Test func snapshotIncludesSpecialPay() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)
        let special = SpecialPayEntry(
            title: "Career Status Bonus",
            date: Calendar.current.date(byAdding: .day, value: 3, to: reference) ?? reference
        )

        let snapshot = PayWidgetBuilder.snapshot(from: reference, specialPays: [special])

        #expect(snapshot.upcoming.contains { $0.title == "Career Status Bonus" })
        #expect(snapshot.upcoming.contains { $0.isSpecial })
    }
}

struct ExploreMapCatalogTests {

    @Test func directPinsIncludeBaseAndGateCoordinates() async {
        let service = LocalJSONDataService()
        guard let base = await service.loadBase(id: "keesler") else {
            Issue.record("Expected keesler base fixture")
            return
        }

        let pins = ExploreMapCatalog.directPins(
            base: base,
            gates: base.gates,
            resources: base.resources,
            events: base.events
        )

        #expect(pins.contains { $0.kind == .base })
        #expect(pins.contains { $0.kind == .gate && $0.title == "Division Street Gate" })
    }

    @Test func addressQueriesSkipItemsWithCoordinates() async {
        let service = LocalJSONDataService()
        guard let base = await service.loadBase(id: "keesler") else {
            Issue.record("Expected keesler base fixture")
            return
        }

        let gateWithCoordinate = base.gates.first { $0.latitude != nil }
        let gateWithoutCoordinate = base.gates.first { $0.latitude == nil && $0.displayAddress != nil }

        #expect(gateWithCoordinate != nil)
        #expect(gateWithoutCoordinate != nil)

        let queries = ExploreMapCatalog.addressQueries(
            base: base,
            gates: base.gates,
            resources: [],
            events: []
        )

        #expect(queries.contains { $0.id == "gate-\(gateWithoutCoordinate!.id)" })
        #expect(!queries.contains { $0.id == "gate-\(gateWithCoordinate!.id)" })
    }
}
