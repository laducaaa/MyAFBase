import Foundation

nonisolated struct AFICorpusChunk: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let publicationID: String
    let publication: String
    let title: String
    let section: String?
    let page: Int?
    let text: String

    enum CodingKeys: String, CodingKey {
        case id
        case publicationID = "publication_id"
        case publication
        case title
        case section
        case page
        case text
    }
}

nonisolated struct AFICorpus: Codable, Sendable {
    let version: String
    let dataUpdatedAt: String
    let chunks: [AFICorpusChunk]
}

enum AFISearchMatchKind: String, Sendable {
    case hybrid
    case keyword
    case semantic
}

struct AFISearchResult: Identifiable, Equatable, Sendable {
    let chunk: AFICorpusChunk
    let score: Double
    let matchKind: AFISearchMatchKind
    let pdfURL: URL?

    var id: String { chunk.id }

    var citationLabel: String {
        var parts = [publication]
        if let section, !section.isEmpty {
            parts.append(section)
        }
        if let page {
            parts.append("p. \(page)")
        }
        return parts.joined(separator: " · ")
    }

    private var publication: String { chunk.publication }
    private var section: String? { chunk.section }
    private var page: Int? { chunk.page }
}
