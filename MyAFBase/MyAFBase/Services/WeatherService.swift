import Foundation

@Observable
final class WeatherService {
    static let shared = WeatherService()

    private let cacheTTL: TimeInterval = 15 * 60

    private init() {}

    func fetchWeather(lat: Double, lon: Double, forceRefresh: Bool = false) async -> Weather {
        let cacheKey = cacheKey(lat: lat, lon: lon)

        if !forceRefresh,
           let cached = loadCachedWeather(forKey: cacheKey),
           Date().timeIntervalSince(cached.lastUpdated) < cacheTTL {
            return cached
        }

        if let nwsWeather = await NWSWeatherService.fetchObservation(lat: lat, lon: lon) {
            cacheWeather(nwsWeather, forKey: cacheKey)
            return nwsWeather
        }

        return await fetchOpenMeteoWeather(lat: lat, lon: lon, cacheKey: cacheKey)
    }

    private func fetchOpenMeteoWeather(lat: Double, lon: Double, cacheKey: String) async -> Weather {
        let query = [
            "latitude=\(lat)",
            "longitude=\(lon)",
            "current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m,is_day,precipitation,cloud_cover",
            "temperature_unit=fahrenheit",
            "wind_speed_unit=mph",
            "precipitation_unit=inch",
            "timezone=auto"
        ].joined(separator: "&")

        let urlString = "https://api.open-meteo.com/v1/forecast?\(query)"

        guard let url = URL(string: urlString) else {
            return loadCachedWeather(forKey: cacheKey) ?? .placeholder()
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let observationTime = parseObservationTime(
                response.current.time,
                timezone: response.timezone
            )

            let resolvedCondition = WeatherCondition.resolved(
                wmoCode: response.current.weatherCode,
                cloudCoverPercent: response.current.cloudCover.map { Int($0.rounded()) },
                precipitationInches: response.current.precipitation
            )

            let weather = Weather(
                tempF: response.current.temperature2M,
                feelsLikeF: response.current.apparentTemperature,
                weatherCode: resolvedCondition.wmoCode,
                windMph: response.current.windSpeed10M,
                humidity: response.current.relativeHumidity2M,
                isDay: response.current.isDay == 1,
                precipitationIn: response.current.precipitation,
                lastUpdated: Date(),
                observationTime: observationTime
            )

            cacheWeather(weather, forKey: cacheKey)
            return weather
        } catch {
            print("Weather fetch failed: \(error)")
            return loadCachedWeather(forKey: cacheKey) ?? .placeholder()
        }
    }

    private func cacheKey(lat: Double, lon: Double) -> String {
        let roundedLat = (lat * 10_000).rounded() / 10_000
        let roundedLon = (lon * 10_000).rounded() / 10_000
        return "lastWeather_v2_\(roundedLat)_\(roundedLon)"
    }

    private func parseObservationTime(_ time: String, timezone: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: time) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: time) {
            return date
        }

        let localFormatter = DateFormatter()
        localFormatter.locale = Locale(identifier: "en_US_POSIX")
        localFormatter.timeZone = TimeZone(identifier: timezone) ?? .current
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        return localFormatter.date(from: time)
    }

    private func cacheWeather(_ weather: Weather, forKey key: String) {
        if let encoded = try? JSONCoding.encoder.encode(weather) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func loadCachedWeather(forKey key: String) -> Weather? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let weather = try? JSONCoding.decoder.decode(Weather.self, from: data) else {
            return nil
        }
        return weather
    }
}

struct OpenMeteoResponse: Codable {
    struct Current: Codable {
        let time: String
        let temperature2M: Double
        let apparentTemperature: Double?
        let weatherCode: Int
        let windSpeed10M: Double
        let relativeHumidity2M: Int
        let isDay: Int
        let precipitation: Double?
        let cloudCover: Double?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2M = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case weatherCode = "weather_code"
            case windSpeed10M = "wind_speed_10m"
            case relativeHumidity2M = "relative_humidity_2m"
            case isDay = "is_day"
            case precipitation
            case cloudCover = "cloud_cover"
        }
    }

    let timezone: String
    let current: Current
}
