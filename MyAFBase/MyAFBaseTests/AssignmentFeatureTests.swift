import Foundation
import Testing
@testable import MyAFBase

struct OpenNowCatalogTests {
    @Test func identifiesOpenDiningResources() {
        let base = Base(
            id: "test",
            name: "Test Base",
            fullName: "Test Base",
            location: "Test",
            description: "",
            wing: "",
            latitude: 0,
            longitude: 0,
            dataUpdatedAt: nil,
            currentNotifications: [],
            emergencyNumbers: [],
            gates: [],
            resources: [
                Resource(
                    id: "dining-1",
                    slug: nil,
                    name: "Dining Facility",
                    category: .dining,
                    description: nil,
                    hours: "Open 24/7",
                    address: nil,
                    phone: nil,
                    url: nil,
                    building: nil,
                    type: .hours,
                    value: nil
                )
            ],
            events: [],
            newcomers: NewcomersInfo(sections: [])
        )

        let openResources = OpenNowCatalog.openResources(in: base)
        #expect(openResources.count == 1)
        #expect(openResources.first?.category == .dining)
    }
}

struct AssignmentProfilePhaseTests {
    @Test func assignmentSegmentRoundTrips() {
        let profile = AssignmentProfile(baseID: "test", phaseRaw: AssignmentSegment.outbound.rawValue)
        #expect(profile.phase == .outbound)
        profile.phase = .stationed
        #expect(profile.phaseRaw == AssignmentSegment.stationed.rawValue)
    }
}
