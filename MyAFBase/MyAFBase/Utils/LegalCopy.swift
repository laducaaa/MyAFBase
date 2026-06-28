import Foundation

/// Centralized legal, privacy, and safety messaging for the app.
enum LegalCopy {
    static let nonAffiliationShort =
        "MyAFBase is an independent community tool. It is not affiliated with, endorsed by, or an official product of the U.S. Department of Defense, Department of the Air Force, or any military installation."

    static let nonAffiliationOneLine =
        "Not affiliated with or endorsed by the DoD, U.S. Air Force, or any military installation."

    static let unofficialInformation =
        "Installation hours, gate access, contacts, and other base information may be outdated or incomplete. Always verify with official sources — your unit, MPF, Security Forces, Visitor Control Center, or official .mil websites — before making decisions."

    static let noPII =
        "Do not enter or submit personally identifiable information (PII), sensitive personnel data, classified information, or Controlled Unclassified Information (CUI) anywhere in this app, including feedback messages."

    static let feedbackPII =
        "Do not include names, phone numbers, unit rosters, orders, clearance details, or other sensitive information in your message. Share only what is needed to describe the issue or idea."

    static let userEnteredData =
        "Readiness due dates, PCS checklists, and assignment details you enter are stored on your device. Some items may sync through your personal iCloud account when signed in. This app is not connected to official personnel, medical, or finance systems."

    static let securityPractices =
        "We design for security with safe link handling, on-device data protection, integrity checks for remotely fetched base data, and minimal data collection when you send feedback."

    static let emergencyVerify =
        "Emergency numbers are compiled from public installation sources and may change. Confirm current numbers with your installation before relying on them in an emergency."

    static let onboardingAcknowledgment =
        "I understand MyAFBase is unofficial, not affiliated with the DoD or U.S. Air Force, and I will not submit PII or sensitive information through the app."

    enum Section: CaseIterable, Identifiable {
        case nonAffiliation
        case unofficialInformation
        case privacyAndData
        case doNotSubmit
        case security

        var id: Self { self }

        var title: String {
            switch self {
            case .nonAffiliation: "Non-Affiliation"
            case .unofficialInformation: "Unofficial Information"
            case .privacyAndData: "Privacy & Your Data"
            case .doNotSubmit: "What Not to Submit"
            case .security: "Security Practices"
            }
        }

        var systemImage: String {
            switch self {
            case .nonAffiliation: "building.columns"
            case .unofficialInformation: "info.circle"
            case .privacyAndData: "hand.raised"
            case .doNotSubmit: "exclamationmark.shield"
            case .security: "lock.shield"
            }
        }

        var body: String {
            switch self {
            case .nonAffiliation: LegalCopy.nonAffiliationShort
            case .unofficialInformation: LegalCopy.unofficialInformation
            case .privacyAndData: LegalCopy.userEnteredData
            case .doNotSubmit: LegalCopy.noPII
            case .security: LegalCopy.securityPractices
            }
        }
    }
}
