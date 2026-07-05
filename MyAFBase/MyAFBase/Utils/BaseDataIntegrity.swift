import CryptoKit
import Foundation

/// Optional SHA-256 verification for remotely fetched base JSON.
/// Add entries to `Resources/BaseData/base_data_manifest.json` at release time.
enum BaseDataIntegrity: Sendable {
    nonisolated static func verify(data: Data, filename: String) -> Bool {
        guard let expected = expectedHash(for: filename) else { return true }
        return SHA256.hash(data: data).hexString == expected.lowercased()
    }

    nonisolated static func validateBase(_ base: Base, expectedID: String) -> Bool {
        base.id == expectedID
    }

    nonisolated private static func expectedHash(for filename: String) -> String? {
        guard let manifest = loadManifestFiles()?[filename] else { return nil }
        let trimmed = manifest.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Decoded via `JSONSerialization` rather than a `Decodable` struct so this stays
    /// free of actor-isolation inference and callable from any background context.
    nonisolated private static func loadManifestFiles() -> [String: String]? {
        guard let url = Bundle.main.url(forResource: "base_data_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object["files"] as? [String: String]
    }
}

private extension SHA256.Digest {
    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
