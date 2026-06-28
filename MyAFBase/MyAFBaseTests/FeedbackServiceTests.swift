import Foundation
import Testing
@testable import MyAFBase

struct FeedbackServiceTests {
    @Test func rejectsShortMessage() async {
        await #expect(throws: FeedbackServiceError.messageTooShort) {
            try await FeedbackService.submit(
                category: .general,
                message: "too short",
                contactEmail: nil,
                contactEmailConsent: false,
                baseID: nil,
                baseName: nil
            )
        }
    }

    @Test func rejectsInvalidEmail() async {
        await #expect(throws: FeedbackServiceError.invalidEmail) {
            try await FeedbackService.submit(
                category: .bug,
                message: "This is a long enough message for validation.",
                contactEmail: "not-an-email",
                contactEmailConsent: true,
                baseID: "keesler",
                baseName: "Keesler AFB"
            )
        }
    }

    @Test func encodesSubmissionPayload() throws {
        let submission = FeedbackSubmission(
            category: .baseData,
            message: "The CDC hours look wrong on Keesler.",
            appVersion: "1.1",
            baseID: "keesler",
            baseName: "Keesler AFB",
            deviceModel: "iPhone",
            osVersion: "iOS 26.2",
            contactEmail: "user@example.com",
            contactEmailConsent: true
        )

        let data = try JSONCoding.encoder.encode(submission)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("baseData"))
        #expect(json.contains("Keesler AFB"))
        #expect(json.contains("contactEmailConsent"))
    }
}
