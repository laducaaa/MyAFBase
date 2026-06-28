import Foundation

enum SafeURL {
    /// Returns a web URL only when the scheme is `http`/`https` and the host is present.
    static func webURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme: String
        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            withScheme = trimmed
        } else {
            withScheme = "https://\(trimmed)"
        }

        guard let url = URL(string: withScheme),
              url.user == nil,
              url.password == nil,
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host,
              !host.isEmpty else {
            return nil
        }
        return url
    }

    /// Host label for display (strips leading `www.`).
    static func displayHost(for raw: String) -> String {
        guard let url = webURL(from: raw), let host = url.host else {
            return raw
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
