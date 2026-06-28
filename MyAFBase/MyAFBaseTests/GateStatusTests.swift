import Foundation
import Testing
@testable import MyAFBase

struct GateStatusTests {

    @Test func gateStatusRoundTrip() throws {
        let json = "\"open\""
        let data = Data(json.utf8)
        let decoded = try JSONCoding.decoder.decode(GateStatus.self, from: data)
        #expect(decoded == .open)

        let encoded = try JSONCoding.encoder.encode(GateStatus.closed)
        let roundTrip = try JSONCoding.decoder.decode(GateStatus.self, from: encoded)
        #expect(roundTrip == .closed)
    }

    @Test func trafficLevelRoundTrip() throws {
        let json = "\"moderate\""
        let data = Data(json.utf8)
        let decoded = try JSONCoding.decoder.decode(TrafficLevel.self, from: data)
        #expect(decoded == .moderate)
    }

    @Test func resourceCategoryAllCases() {
        #expect(ResourceCategory.allCases.count == 10)
    }
}
