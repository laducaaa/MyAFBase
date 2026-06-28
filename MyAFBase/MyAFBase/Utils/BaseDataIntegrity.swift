import CryptoKit
import Foundation

/// Optional SHA-256 verification for remotely fetched base JSON.
/// Add entries to `Resources/BaseData/base_data_manifest.json` at release time.
enum BaseDataIntegrity: Sendable {
    private struct Manifest: Decodable {
        let files: [String: String]
    }

    nonisolated static func verify(data: Data, filename: String) -> Bool {
        guard let expected = expectedHash(for: filename) else { return true }
        return SHA256.hash(data: data).hexString == expected.lowercased()
    }

    nonisolated static func validateBase(_ base: Base, expectedID: String) -> Bool {
        base.id == expectedID
    }

    nonisolated private static func expectedHash(for filename: String) -> String? {
        guard let manifest = loadManifest()?.files[filename] else { return nil }
        let trimmed = manifest.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    nonisolated private static func loadManifest() -> Manifest? {
        guard let url = Bundle.main.url(forResource: "base_data_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(Manifest.self, from: data)
    }
}

private extension SHA256.Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
