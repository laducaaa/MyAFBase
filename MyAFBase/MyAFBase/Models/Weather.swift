import Foundation

enum WeatherCondition: Equatable {
    case clear
    case mainlyClear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case freezingDrizzle
    case rain
    case freezingRain
    case snow
    case rainShowers
    case snowShowers
    case thunderstorm
    case unknown

    static func from(wmoCode: Int) -> WeatherCondition {
        switch wmoCode {
        case 0: return .clear
        case 1: return .mainlyClear
        case 2: return .partlyCloudy
        case 3: return .overcast
        case 45, 48: return .fog
        case 51, 53, 55: return .drizzle
        case 56, 57: return .freezingDrizzle
        case 61, 63, 65: return .rain
        case 66, 67: return .freezingRain
        case 71, 73, 75, 77: return .snow
        case 80, 81, 82: return .rainShowers
        case 85, 86: return .snowShowers
        case 95, 96, 99: return .thunderstorm
        default: return .unknown
        }
    }

    static func from(nwsDescription: String) -> WeatherCondition {
        let text = nwsDescription.lowercased()

        if text.contains("thunder") {
            return .thunderstorm
        }
        if text.contains("snow") || text.contains("sleet") || text.contains("ice pellet") {
            return .snow
        }
        if text.contains("freezing rain") {
            return .freezingRain
        }
        if text.contains("drizzle") {
            return .drizzle
        }
        if text.contains("shower") {
            return .rainShowers
        }
        if text.contains("rain") {
            return .rain
        }
        if text.contains("fog") || text.contains("mist") || text.contains("haze") {
            return .fog
        }
        if text.contains("overcast") {
            return .overcast
        }
        if text.contains("mostly cloudy") {
            return .overcast
        }
        if text.contains("partly cloudy") || text.contains("partly sunny") {
            return .partlyCloudy
        }
        if text.contains("mostly clear") || text.contains("fair") {
            return .mainlyClear
        }
        if text.contains("clear") || text.contains("sunny") {
            return .clear
        }

        return .unknown
    }

    /// Open-Meteo can flag thunderstorms from atmospheric instability even when skies are clear.
    /// Reconcile using measured precipitation and cloud cover when available.
    static func resolved(
        wmoCode: Int,
        cloudCoverPercent: Int?,
        precipitationInches: Double?
    ) -> WeatherCondition {
        let raw = from(wmoCode: wmoCode)
        let precip = max(precipitationInches ?? 0, 0)
        let hasSignificantPrecip = precip >= 0.01

        guard isPrecipitationRelated(wmoCode: wmoCode), !hasSignificantPrecip else {
            return raw
        }

        if let cloudCoverPercent {
            return fromCloudCover(cloudCoverPercent)
        }

        if wmoCode >= 95 {
            return .partlyCloudy
        }

        return raw
    }

    private static func isPrecipitationRelated(wmoCode: Int) -> Bool {
        switch wmoCode {
        case 51...67, 71...77, 80...86, 95...99:
            return true
        default:
            return false
        }
    }

    private static func fromCloudCover(_ percent: Int) -> WeatherCondition {
        switch percent {
        case 0...15: return .clear
        case 16...30: return .mainlyClear
        case 31...55: return .partlyCloudy
        default: return .overcast
        }
    }

    var wmoCode: Int {
        switch self {
        case .clear: return 0
        case .mainlyClear: return 1
        case .partlyCloudy: return 2
        case .overcast: return 3
        case .fog: return 45
        case .drizzle: return 53
        case .freezingDrizzle: return 56
        case .rain: return 63
        case .freezingRain: return 66
        case .snow: return 73
        case .rainShowers: return 81
        case .snowShowers: return 85
        case .thunderstorm: return 95
        case .unknown: return 2
        }
    }

    var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .mainlyClear: return "Mainly Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .overcast: return "Overcast"
        case .fog: return "Fog"
        case .drizzle: return "Drizzle"
        case .freezingDrizzle: return "Freezing Drizzle"
        case .rain: return "Rain"
        case .freezingRain: return "Freezing Rain"
        case .snow: return "Snow"
        case .rainShowers: return "Rain Showers"
        case .snowShowers: return "Snow Showers"
        case .thunderstorm: return "Thunderstorm"
        case .unknown: return "Unknown"
        }
    }

    var symbolName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .mainlyClear: return "sun.min.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .fog: return "cloud.fog.fill"
        case .drizzle, .freezingDrizzle: return "cloud.drizzle.fill"
        case .rain, .freezingRain, .rainShowers: return "cloud.rain.fill"
        case .snow, .snowShowers: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    /// Groups conditions for hero background styling.
    var themeKey: String {
        switch self {
        case .clear, .mainlyClear: return "clear"
        case .partlyCloudy: return "partly cloudy"
        case .overcast: return "cloudy"
        case .fog: return "fog"
        case .drizzle, .freezingDrizzle, .rain, .freezingRain, .rainShowers: return "rain"
        case .snow, .snowShowers: return "snow"
        case .thunderstorm: return "thunderstorm"
        case .unknown: return "unknown"
        }
    }
}

struct Weather: Codable, Equatable {
    let tempF: Double
    let feelsLikeF: Double?
    let weatherCode: Int
    let windMph: Double
    let humidity: Int
    let isDay: Bool
    let precipitationIn: Double?
    let lastUpdated: Date
    let observationTime: Date?

    var condition: WeatherCondition {
        WeatherCondition.from(wmoCode: weatherCode)
    }

    var conditionName: String {
        isPlaceholder ? "Unavailable" : condition.displayName
    }

    static func placeholder() -> Weather {
        Weather(
            tempF: 0,
            feelsLikeF: nil,
            weatherCode: -1,
            windMph: 0,
            humidity: 0,
            isDay: true,
            precipitationIn: nil,
            lastUpdated: Date(),
            observationTime: nil
        )
    }

    var isPlaceholder: Bool {
        weatherCode < 0 && tempF == 0
    }

    var feelsLikeDisplayF: Int? {
        guard let feelsLikeF, !isPlaceholder else { return nil }
        let rounded = Int(feelsLikeF.rounded())
        guard abs(Double(rounded) - tempF.rounded()) >= 2 else { return nil }
        return rounded
    }
}
