import Foundation

enum NWSWeatherService {
    private static let userAgent = "MyAFBase/1.0 (iOS weather)"

    static func fetchObservation(lat: Double, lon: Double) async -> Weather? {
        guard let stationID = await nearestStationID(lat: lat, lon: lon) else {
            return nil
        }

        return await latestObservation(for: stationID)
    }

    private static func nearestStationID(lat: Double, lon: Double) async -> String? {
        let pointsURL = URL(string: "https://api.weather.gov/points/\(lat),\(lon)")
        guard let pointsURL,
              let points = await decode(NWSPointsResponse.self, from: pointsURL),
              let stationsURL = URL(string: points.properties.observationStations) else {
            return nil
        }

        guard let stations = await decode(NWSStationsResponse.self, from: stationsURL),
              let stationID = stations.features.first?.properties.stationIdentifier else {
            return nil
        }

        return stationID
    }

    private static func latestObservation(for stationID: String) async -> Weather? {
        let url = URL(string: "https://api.weather.gov/stations/\(stationID)/observations/latest")
        guard let url,
              let response = await decode(NWSObservationResponse.self, from: url) else {
            return nil
        }

        let properties = response.properties
        guard let description = properties.textDescription,
              !description.isEmpty,
              let temperatureC = properties.temperature?.value else {
            return nil
        }

        let condition = WeatherCondition.from(nwsDescription: description)
        let tempF = (temperatureC * 9 / 5) + 32
        let windMph = properties.windSpeed?.value.map { $0 * 0.621371 } ?? 0
        let humidity = Int((properties.relativeHumidity?.value ?? 0).rounded())
        let observationTime = parseTimestamp(properties.timestamp)

        return Weather(
            tempF: tempF,
            feelsLikeF: properties.heatIndex?.value.map { ($0 * 9 / 5) + 32 },
            weatherCode: condition.wmoCode,
            windMph: windMph,
            humidity: humidity,
            isDay: true,
            precipitationIn: properties.precipitationLastHour?.value.map { $0 / 25.4 },
            lastUpdated: Date(),
            observationTime: observationTime
        )
    }

    private static func parseTimestamp(_ value: String?) -> Date? {
        guard let value else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from url: URL) async -> T? {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("NWS fetch failed: \(error)")
            return nil
        }
    }
}

private struct NWSPointsResponse: Decodable {
    struct Properties: Decodable {
        let observationStations: String
    }

    let properties: Properties
}

private struct NWSStationsResponse: Decodable {
    struct Feature: Decodable {
        struct Properties: Decodable {
            let stationIdentifier: String
        }

        let properties: Properties
    }

    let features: [Feature]
}

private struct NWSObservationResponse: Decodable {
    struct Properties: Decodable {
        struct Measurement: Decodable {
            let value: Double?
        }

        let timestamp: String?
        let textDescription: String?
        let temperature: Measurement?
        let relativeHumidity: Measurement?
        let windSpeed: Measurement?
        let heatIndex: Measurement?
        let precipitationLastHour: Measurement?
    }

    let properties: Properties
}
