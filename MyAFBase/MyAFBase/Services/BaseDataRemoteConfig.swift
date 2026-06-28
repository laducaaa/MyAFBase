import Foundation

/// GitHub-hosted base JSON served via `raw.githubusercontent.com`.
/// Update `repository` after creating the remote repo.
enum BaseDataRemoteConfig: Sendable {
    nonisolated static let repository = "laducaaa/MyAFBase"

    /// Pin remote fetches to a commit SHA or release tag instead of a moving branch when possible.
    nonisolated static let pinnedRef = "main"

    nonisolated static let basesPath = "MyAFBase/MyAFBase/Resources/Bases"

    /// Minimum time between automatic background index syncs.
    nonisolated static let indexRefreshInterval: TimeInterval = 60 * 60

    /// Minimum time between automatic per-base syncs.
    nonisolated static let baseRefreshInterval: TimeInterval = 30 * 60

    nonisolated static var indexURL: URL {
        remoteURL(filename: "bases_index.json")
    }

    nonisolated static func baseURL(id: String) -> URL? {
        guard BaseIDValidator.sanitize(id) != nil else { return nil }
        return remoteURL(filename: "\(id).json")
    }

    nonisolated private static func remoteURL(filename: String) -> URL {
        let path = [basesPath, filename].joined(separator: "/")
        return URL(string: "https://raw.githubusercontent.com/\(repository)/\(pinnedRef)/\(path)")!
    }
}
