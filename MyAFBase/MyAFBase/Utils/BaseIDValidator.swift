import Foundation

enum BaseIDValidator {
    private static let slugPattern = #"^[a-z0-9]+(?:-[a-z0-9]+)*$"#

    /// Validates base IDs used in remote URLs and on-disk cache filenames.
    static func sanitize(_ id: String) -> String? {
        guard id.count <= 64,
              id.range(of: slugPattern, options: .regularExpression) != nil else {
            return nil
        }
        return id
    }

    static func cacheFilename(for id: String) -> String? {
        guard let safe = sanitize(id) else { return nil }
        return "\(safe).json"
    }
}
