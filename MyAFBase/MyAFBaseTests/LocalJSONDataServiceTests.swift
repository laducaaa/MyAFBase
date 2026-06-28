import Foundation
import Testing
@testable import MyAFBase

struct LocalJSONDataServiceTests {

    @Test func decodesKeeslerBaseFromFixture() throws {
        let data = Data(Self.keeslerFixture.utf8)
        let base = try JSONCoding.decoder.decode(Base.self, from: data)

        #expect(base.id == "keesler")
        #expect(base.name == "Keesler AFB")
        #expect(base.latitude == 30.41)
        #expect(base.longitude == -88.92)
        #expect(!base.gates.isEmpty)
        #expect(!base.resources.isEmpty)
    }

    @Test func decodesBaseIndexFromFixture() throws {
        let data = Data(Self.indexFixture.utf8)
        let entries = try JSONCoding.decoder.decode([BaseIndexEntry].self, from: data)

        #expect(entries.count == 1)
        #expect(entries.first?.id == "keesler")
    }

    @Test func loadsBaseIndexFromBundle() async {
        let service = LocalJSONDataService()
        let index = await service.loadBaseIndex()
        #expect(!index.isEmpty)
        #expect(index.contains { $0.id == "keesler" })
    }

    @Test func loadsKeeslerFromBundle() async {
        let service = LocalJSONDataService()
        let base = await service.loadBase(id: "keesler")
        #expect(base != nil)
        #expect(base?.id == "keesler")
    }

    @Test func missingBaseReturnsNil() async {
        let service = LocalJSONDataService()
        let base = await service.loadBase(id: "nonexistent-base-id")
        #expect(base == nil)
    }

    @Test func loadPickerBaseIndexExcludesOconusAndUnlistedBases() async {
        let service = LocalJSONDataService()
        let pickerIndex = await service.loadPickerBaseIndex()
        let fullIndex = await service.loadBaseIndex()

        #expect(!pickerIndex.isEmpty)
        #expect(pickerIndex.allSatisfy { $0.region == .conus })
        #expect(pickerIndex.allSatisfy { BaseCatalog.isListedInPicker($0) })
        #expect(pickerIndex.contains { $0.id == "keesler" })
        #expect(!pickerIndex.contains { $0.id == "ramstein" })
        #expect(!pickerIndex.contains { $0.id == "altus" })
        #expect(pickerIndex.count < fullIndex.count)
    }

    @Test func allIndexEntriesHaveMatchingBaseFiles() async {
        let service = LocalJSONDataService()
        let index = await service.loadBaseIndex()

        for entry in index {
            let base = await service.loadBase(id: entry.id)
            #expect(base != nil, "Missing base file for \(entry.id)")
            #expect(base?.id == entry.id)
        }
    }

    private static let indexFixture = """
    [
      { "id": "keesler", "name": "Keesler AFB", "location": "Biloxi, MS", "wing": "81 TRW", "region": "conus" }
    ]
    """

    private static let keeslerFixture = """
    {
      "id": "keesler",
      "name": "Keesler AFB",
      "fullName": "Keesler Air Force Base",
      "location": "Biloxi, MS",
      "description": "Test base",
      "wing": "81 TRW",
      "latitude": 30.41,
      "longitude": -88.92,
      "currentNotifications": [],
      "emergencyNumbers": [],
      "gates": [{ "id": "g1", "name": "Gate 1", "status": "open", "hours": "24/7", "notes": null, "traffic": "low" }],
      "resources": [{ "id": "r1", "name": "Test Resource", "category": "services", "type": "phone", "value": "555-0100", "description": null, "hours": null }],
      "events": [],
      "newcomers": { "sections": [] }
    }
    """
}
