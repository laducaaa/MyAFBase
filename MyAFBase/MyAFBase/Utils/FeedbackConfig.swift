import Foundation

/// In-app feedback is delivered as GitHub Issues via a free Cloudflare Worker.
/// See `scripts/feedback-worker/` for one-time deployment steps.
enum FeedbackConfig {
    /// Cloudflare Worker URL after deploy (e.g. `https://myafbase-feedback.your-subdomain.workers.dev`).
    /// Set to `nil` until deployed — the feedback form will explain how to enable it.
    static let endpoint: URL? = URL(string: "https://myafbase-feedback.rladuca92.workers.dev")

    /// Shared secret matching `FEEDBACK_SECRET` on the worker.
    /// Set `FEEDBACK_SHARED_SECRET` in the app Info.plist (or target build settings).
    /// Treat as abuse deterrence — the worker also rate-limits by IP.
    static var sharedSecret: String? {
        let value = Bundle.main.object(forInfoDictionaryKey: "FEEDBACK_SHARED_SECRET") as? String
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static let githubRepository = BaseDataRemoteConfig.repository
    static let minimumMessageLength = 12
    static let maximumMessageLength = 4_000
}

enum FeedbackCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case bug
    case feature
    case baseData
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bug: "Bug Report"
        case .feature: "Feature Request"
        case .baseData: "Base Data Correction"
        case .general: "General Feedback"
        }
    }

    var systemImage: String {
        switch self {
        case .bug: "ladybug.fill"
        case .feature: "lightbulb.fill"
        case .baseData: "map.fill"
        case .general: "text.bubble.fill"
        }
    }

    var chipTitle: String {
        switch self {
        case .bug: "Bug"
        case .feature: "Idea"
        case .baseData: "Base Data"
        case .general: "Other"
        }
    }

    var messagePlaceholder: String {
        switch self {
        case .bug:
            "What went wrong? Include steps to reproduce if you can."
        case .feature:
            "What would you like the app to do? Tell us how it would help you."
        case .baseData:
            "Which base, resource, or hours are incorrect? Include what it should say."
        case .general:
            "Share your thoughts — we're listening."
        }
    }
}

struct FeedbackSubmission: Codable, Sendable, Equatable {
    let category: FeedbackCategory
    let message: String
    let appVersion: String
    let baseID: String?
    let baseName: String?
    let deviceModel: String
    let osVersion: String
    let contactEmail: String?
    let contactEmailConsent: Bool
}

enum FeedbackServiceError: LocalizedError, Equatable {
    case notConfigured
    case messageTooShort
    case messageTooLong
    case invalidEmail
    case network
    case serverRejected

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Feedback isn't connected yet. Deploy the free worker in scripts/feedback-worker and set FeedbackConfig.endpoint."
        case .messageTooShort:
            "Please add a bit more detail so we can help."
        case .messageTooLong:
            "Please shorten your message."
        case .invalidEmail:
            "Enter a valid email address or leave the field blank."
        case .network:
            "Couldn't reach the feedback service. Check your connection and try again."
        case .serverRejected:
            "The feedback service couldn't accept this submission. Try again later."
        }
    }
}

enum FeedbackService {
    static func submit(
        category: FeedbackCategory,
        message: String,
        contactEmail: String?,
        contactEmailConsent: Bool,
        baseID: String?,
        baseName: String?
    ) async throws {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= FeedbackConfig.minimumMessageLength else {
            throw FeedbackServiceError.messageTooShort
        }
        guard trimmed.count <= FeedbackConfig.maximumMessageLength else {
            throw FeedbackServiceError.messageTooLong
        }

        let email = contactEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
        if contactEmailConsent, let email, !email.isEmpty, !isValidEmail(email) {
            throw FeedbackServiceError.invalidEmail
        }

        guard let endpoint = FeedbackConfig.endpoint else {
            throw FeedbackServiceError.notConfigured
        }

        let payload = FeedbackSubmission(
            category: category,
            message: trimmed,
            appVersion: AppReleaseNotes.appVersion,
            baseID: baseID,
            baseName: baseName,
            deviceModel: deviceModelName(),
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            contactEmail: contactEmailConsent ? email?.isEmpty == true ? nil : email : nil,
            contactEmailConsent: contactEmailConsent && email?.isEmpty == false
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MyAFBase-iOS/\(AppReleaseNotes.appVersion)", forHTTPHeaderField: "User-Agent")
        if let secret = FeedbackConfig.sharedSecret {
            request.setValue(secret, forHTTPHeaderField: "X-Feedback-Secret")
        }
        request.httpBody = try JSONCoding.encoder.encode(payload)
        request.timeoutInterval = 25

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FeedbackServiceError.network
        }

        guard (200 ... 299).contains(http.statusCode) else {
            if http.statusCode == 503, let body = String(data: data, encoding: .utf8), body.contains("not_configured") {
                throw FeedbackServiceError.notConfigured
            }
            throw FeedbackServiceError.serverRejected
        }
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private static func deviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        return identifier
    }
}
