import Foundation
import Testing
@testable import MyAFBase

struct WeatherServiceTests {

    @Test func decodesOpenMeteoResponse() throws {
        let data = Data(Self.sampleResponse.utf8)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        #expect(response.current.temperature2M == 72.5)
        #expect(response.current.apparentTemperature == 74.0)
        #expect(response.current.weatherCode == 95)
        #expect(response.current.cloudCover == 18)
        #expect(response.current.windSpeed10M == 8.3)
        #expect(response.current.relativeHumidity2M == 65)
        #expect(response.current.isDay == 1)
        #expect(response.timezone == "America/Chicago")
    }

    @Test func weatherPlaceholder() {
        let placeholder = Weather.placeholder()
        #expect(placeholder.isPlaceholder)
        #expect(placeholder.conditionName == "Unavailable")
    }

    @Test func weatherCodableRoundTrip() throws {
        let weather = Weather(
            tempF: 75,
            feelsLikeF: 78,
            weatherCode: 0,
            windMph: 10,
            humidity: 50,
            isDay: true,
            precipitationIn: 0,
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000),
            observationTime: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONCoding.encoder.encode(weather)
        let decoded = try JSONCoding.decoder.decode(Weather.self, from: data)

        #expect(decoded.tempF == 75)
        #expect(decoded.conditionName == "Clear")
        #expect(decoded.humidity == 50)
        #expect(decoded.feelsLikeDisplayF == 78)
    }

    @Test func mapsWMOWeatherCodes() {
        #expect(WeatherCondition.from(wmoCode: 0).displayName == "Clear")
        #expect(WeatherCondition.from(wmoCode: 2).displayName == "Partly Cloudy")
        #expect(WeatherCondition.from(wmoCode: 3).displayName == "Overcast")
        #expect(WeatherCondition.from(wmoCode: 61).displayName == "Rain")
        #expect(WeatherCondition.from(wmoCode: 95).displayName == "Thunderstorm")
        #expect(WeatherCondition.from(wmoCode: 99).displayName == "Thunderstorm")
    }

    @Test func mapsNWSObservationText() {
        #expect(WeatherCondition.from(nwsDescription: "Mostly Clear").displayName == "Mainly Clear")
        #expect(WeatherCondition.from(nwsDescription: "Clear").displayName == "Clear")
        #expect(WeatherCondition.from(nwsDescription: "Partly Cloudy").displayName == "Partly Cloudy")
        #expect(WeatherCondition.from(nwsDescription: "Thunderstorm in Vicinity").displayName == "Thunderstorm")
    }

    @Test func reconcilesFalseThunderstormFromOpenMeteo() {
        let condition = WeatherCondition.resolved(
            wmoCode: 95,
            cloudCoverPercent: 18,
            precipitationInches: 0
        )

        #expect(condition.displayName == "Mainly Clear")
    }

    @Test func keepsThunderstormWhenPrecipitationIsPresent() {
        let condition = WeatherCondition.resolved(
            wmoCode: 95,
            cloudCoverPercent: 80,
            precipitationInches: 0.2
        )

        #expect(condition.displayName == "Thunderstorm")
    }

    @Test func feelsLikeHiddenWhenCloseToActualTemp() {
        let weather = Weather(
            tempF: 75,
            feelsLikeF: 76,
            weatherCode: 0,
            windMph: 5,
            humidity: 40,
            isDay: true,
            precipitationIn: nil,
            lastUpdated: Date(),
            observationTime: nil
        )

        #expect(weather.feelsLikeDisplayF == nil)
    }

    private static let sampleResponse = """
    {
      "timezone": "America/Chicago",
      "current": {
        "time": "2026-06-23T12:30",
        "temperature_2m": 72.5,
        "apparent_temperature": 74.0,
        "weather_code": 95,
        "wind_speed_10m": 8.3,
        "relative_humidity_2m": 65,
        "is_day": 1,
        "precipitation": 0.02,
        "cloud_cover": 18
      }
    }
    """
}
