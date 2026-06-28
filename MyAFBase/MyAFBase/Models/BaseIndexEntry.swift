import Foundation

struct BaseIndexEntry: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let location: String
    let wing: String
    let region: BaseRegion
}
