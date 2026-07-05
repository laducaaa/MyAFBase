import Testing
@testable import MyAFBase

struct WARPIIScannerTests {

    @Test func flagsSSNPattern() {
        #expect(WARPIIScanner.containsLikelyPII("SSN is 123-45-6789"))
    }

    @Test func flagsPhonePattern() {
        #expect(WARPIIScanner.containsLikelyPII("Call 555-123-4567 for details"))
    }

    @Test func flagsClassifiedKeywords() {
        #expect(WARPIIScanner.containsLikelyPII("This was a Secret// mission"))
    }

    @Test func ignoresOrdinaryText() {
        #expect(!WARPIIScanner.containsLikelyPII("Led a team of 4 to complete the quarterly inspection early."))
    }
}
