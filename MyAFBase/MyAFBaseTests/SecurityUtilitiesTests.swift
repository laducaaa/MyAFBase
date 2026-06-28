import Foundation
import Testing
@testable import MyAFBase

struct SecurityUtilitiesTests {
    @Test func safeURLAcceptsHTTPS() {
        let url = SafeURL.webURL(from: "https://www.tricare.mil/")
        #expect(url?.scheme == "https")
        #expect(url?.host == "www.tricare.mil")
    }

    @Test func safeURLPrependsHTTPSForBareHost() {
        let url = SafeURL.webURL(from: "www.af.mil")
        #expect(url?.scheme == "https")
        #expect(url?.host == "www.af.mil")
    }

    @Test func safeURLRejectsJavaScriptScheme() {
        #expect(SafeURL.webURL(from: "javascript:alert(1)") == nil)
    }

    @Test func safeURLRejectsUserinfoTrick() {
        #expect(SafeURL.webURL(from: "https://evil@trusted.mil") == nil)
    }

    @Test func baseIDValidatorAcceptsSlug() {
        #expect(BaseIDValidator.sanitize("keesler") == "keesler")
        #expect(BaseIDValidator.sanitize("fe-warren") == "fe-warren")
    }

    @Test func baseIDValidatorRejectsTraversal() {
        #expect(BaseIDValidator.sanitize("../keesler") == nil)
        #expect(BaseIDValidator.sanitize("keesler/../../etc") == nil)
    }

    @Test func diskCacheRejectsPathTraversalFilename() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let cache = BaseDataDiskCache(
            directoryURL: directory,
            metadataDefaults: defaults
        )

        cache.write(Data("blocked".utf8), filename: "../outside.json")
        #expect(cache.read(filename: "../outside.json") == nil)

        let outsideURL = directory.deletingLastPathComponent().appendingPathComponent("outside.json")
        #expect(FileManager.default.fileExists(atPath: outsideURL.path) == false)
    }

    @Test func baseIntegrityAllowsMissingManifestEntry() {
        let data = Data("{\"id\":\"keesler\"}".utf8)
        #expect(BaseDataIntegrity.verify(data: data, filename: "unlisted.json") == true)
    }

    @Test func baseIntegrityValidatesMatchingID() {
        let base = Base(
            id: "keesler",
            name: "Keesler AFB",
            fullName: "Keesler Air Force Base",
            location: "Biloxi, MS",
            description: "Test",
            wing: "81 TRW",
            latitude: 30.41,
            longitude: -88.92,
            dataUpdatedAt: nil,
            currentNotifications: [],
            emergencyNumbers: [],
            gates: [],
            resources: [],
            events: [],
            newcomers: NewcomersInfo(sections: [])
        )
        #expect(BaseDataIntegrity.validateBase(base, expectedID: "keesler"))
        #expect(!BaseDataIntegrity.validateBase(base, expectedID: "hill"))
    }
}
