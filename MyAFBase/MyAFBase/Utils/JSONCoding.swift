import Foundation

enum JSONCoding: Sendable {
    nonisolated static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    nonisolated static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    nonisolated static func decodeBase(from data: Data) async -> Base? {
        await MainActor.run {
            try? decoder.decode(Base.self, from: data)
        }
    }
}
