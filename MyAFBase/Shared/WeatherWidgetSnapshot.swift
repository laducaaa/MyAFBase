import Foundation

struct WeatherWidgetSnapshot: Codable, Equatable, Sendable {
    var baseID: String
    var baseName: String
    var location: String?
    var tempF: Int?
    var feelsLikeF: Int?
    var conditionName: String
    var symbolName: String
    var windMph: Int?
    var humidity: Int?
    var isAvailable: Bool
    var updatedAt: Date

    var tempDisplay: String {
        guard let tempF else { return "—" }
        return "\(tempF)°"
    }

    var feelsLikeDisplay: String? {
        guard let feelsLikeF else { return nil }
        return "Feels \(feelsLikeF)°"
    }
}
