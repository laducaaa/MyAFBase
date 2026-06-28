import Foundation

/// GitHub-hosted base JSON served via `raw.githubusercontent.com`.
/// Update `repository` after creating the remote repo.
enum BaseDataRemoteConfig {
    static let repository = "laducaaa/MyAFBase"
    static let branch = "main"
    static let basesPath = "MyAFBase/MyAFBase/Resources/Bases"

    /// Minimum time between automatic background index syncs.
    static let indexRefreshInterval: TimeInterval = 60 * 60

    /// Minimum time between automatic per-base syncs.
    static let baseRefreshInterval: TimeInterval = 30 * 60

    static var indexURL: URL {
        remoteURL(filename: "bases_index.json")
    }

    static func baseURL(id: String) -> URL {
        remoteURL(filename: "\(id).json")
    }

    private static func remoteURL(filename: String) -> URL {
        let path = [basesPath, filename].joined(separator: "/")
        return URL(string: "https://raw.githubusercontent.com/\(repository)/\(branch)/\(path)")!
    }
}
