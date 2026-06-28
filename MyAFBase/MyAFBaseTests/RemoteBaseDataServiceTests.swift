import Foundation
import Testing
@testable import MyAFBase

struct BaseDataDiskCacheTests {

    @Test func writesAndReadsData() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let cache = BaseDataDiskCache(
            directoryURL: directory,
            metadataDefaults: defaults
        )

        let payload = Data("test-index".utf8)
        cache.write(payload, filename: "bases_index.json")

        #expect(cache.read(filename: "bases_index.json") == payload)
        #expect(cache.lastFetched(filename: "bases_index.json") != nil)
    }

    @Test func staleAfterMaxAge() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let cache = BaseDataDiskCache(
            directoryURL: directory,
            metadataDefaults: defaults
        )

        cache.write(Data("{}".utf8), filename: "keesler.json")
        #expect(cache.isStale(filename: "keesler.json", maxAge: 0) == true)
        #expect(cache.isStale(filename: "keesler.json", maxAge: 3600) == false)
    }

    @Test func missingFileIsStale() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let cache = BaseDataDiskCache(
            directoryURL: directory,
            metadataDefaults: defaults
        )

        #expect(cache.read(filename: "missing.json") == nil)
        #expect(cache.isStale(filename: "missing.json", maxAge: 60) == true)
    }
}

struct RemoteAwareBaseDataServiceTests {

    @Test func loadsKeeslerFromBundleWhenRemoteCacheEmpty() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let cache = BaseDataDiskCache(
            directoryURL: directory,
            metadataDefaults: defaults
        )
        let service = RemoteAwareBaseDataService(cache: cache)

        let base = await service.loadBase(id: "keesler")
        #expect(base?.id == "keesler")
    }

    @Test func prefersNewerRemoteBaseFromCache() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let cache = BaseDataDiskCache(
            directoryURL: directory,
            metadataDefaults: defaults
        )

        let remoteFixture = """
        {
          "id": "keesler",
          "name": "Keesler AFB",
          "fullName": "Keesler Air Force Base",
          "location": "Biloxi, MS",
          "description": "Remote copy",
          "wing": "81 TRW",
          "latitude": 30.41,
          "longitude": -88.92,
          "dataUpdatedAt": "2099-01-01T00:00:00Z",
          "currentNotifications": [],
          "emergencyNumbers": [],
          "gates": [],
          "resources": [],
          "events": [],
          "newcomers": { "sections": [] }
        }
        """
        cache.write(Data(remoteFixture.utf8), filename: "keesler.json")

        let service = RemoteAwareBaseDataService(cache: cache)
        let base = await service.loadBase(id: "keesler")

        #expect(base?.description == "Remote copy")
        #expect(base?.dataUpdatedAt == "2099-01-01T00:00:00Z")
    }

    @Test func remoteIndexMergesWithBundle() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let cache = BaseDataDiskCache(
            directoryURL: directory,
            metadataDefaults: defaults
        )

        let bundledService = LocalJSONDataService()
        let bundledIndex = await bundledService.loadBaseIndex()
        #expect(!bundledIndex.isEmpty)

        let remoteOnlyEntry = """
        [
          { "id": "remote-only-base", "name": "Remote Base", "location": "Test, TS", "wing": "99 ABW", "region": "conus" }
        ]
        """
        cache.write(Data(remoteOnlyEntry.utf8), filename: "bases_index.json")

        let service = RemoteAwareBaseDataService(cache: cache)
        let merged = await service.loadBaseIndex()

        #expect(merged.contains { $0.id == "keesler" })
        #expect(merged.contains { $0.id == "remote-only-base" })
    }
}
