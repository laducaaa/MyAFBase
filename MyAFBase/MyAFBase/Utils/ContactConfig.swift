import Foundation

/// Public contact channels for MyAFBase support and legal inquiries.
enum ContactConfig {
    static let supportEmail = "support@myafbase.com"
    static let legalEmail = "legal@myafbase.com"

    static let websiteURL = URL(string: "https://myafbase.com")!
    static let supportURL = URL(string: "https://myafbase.com/support")!
    static let privacyURL = URL(string: "https://myafbase.com/privacy")!
    static let userChoicesURL = URL(string: "https://myafbase.com/user-choices")!
    static let termsURL = URL(string: "https://myafbase.com/terms")!

    static var supportMailtoURL: URL? {
        URL(string: "mailto:\(supportEmail)")
    }

    static var legalMailtoURL: URL? {
        URL(string: "mailto:\(legalEmail)")
    }
}
