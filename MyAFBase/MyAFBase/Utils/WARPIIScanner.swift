import Foundation

/// Lightweight, advisory-only heuristic for common PII patterns in WAR entry
/// text. This never blocks saving or exporting — it just surfaces a gentle
/// warning so the user can redact before sharing outside the app.
enum WARPIIScanner {
    private static let ssnPattern = #"\b\d{3}-\d{2}-\d{4}\b"#
    private static let phonePattern = #"\b\d{3}[-.\s]\d{3}[-.\s]\d{4}\b"#
    private static let sensitiveKeywords = [
        "ssn", "social security", "classified", "secret//", "top secret", "cui"
    ]

    static func containsLikelyPII(_ text: String) -> Bool {
        let lowered = text.lowercased()

        if sensitiveKeywords.contains(where: { lowered.contains($0) }) {
            return true
        }

        if text.range(of: ssnPattern, options: .regularExpression) != nil {
            return true
        }

        if text.range(of: phonePattern, options: .regularExpression) != nil {
            return true
        }

        return false
    }
}
