import Foundation

enum WidgetDataStore {
    static let appGroupID = "group.com.ryanladuca.MyAFBase"

    private static let readinessKey = "readinessWidgetSnapshot"
    private static let weatherKey = "weatherWidgetSnapshot"
    private static let openNowKey = "openNowWidgetSnapshot"
    private static let emergencyKey = "emergencyWidgetSnapshot"
    private static let payKey = "payWidgetSnapshot"
    private static let warTrackerKey = "warTrackerWidgetSnapshot"

    static func saveReadiness(_ snapshot: ReadinessWidgetSnapshot) {
        save(snapshot, forKey: readinessKey)
    }

    static func loadReadiness() -> ReadinessWidgetSnapshot? {
        load(ReadinessWidgetSnapshot.self, forKey: readinessKey)
    }

    static func saveWeather(_ snapshot: WeatherWidgetSnapshot) {
        save(snapshot, forKey: weatherKey)
    }

    static func loadWeather() -> WeatherWidgetSnapshot? {
        load(WeatherWidgetSnapshot.self, forKey: weatherKey)
    }

    static func saveOpenNow(_ snapshot: OpenNowWidgetSnapshot) {
        save(snapshot, forKey: openNowKey)
    }

    static func loadOpenNow() -> OpenNowWidgetSnapshot? {
        load(OpenNowWidgetSnapshot.self, forKey: openNowKey)
    }

    static func saveEmergency(_ snapshot: EmergencyWidgetSnapshot) {
        save(snapshot, forKey: emergencyKey)
    }

    static func loadEmergency() -> EmergencyWidgetSnapshot? {
        load(EmergencyWidgetSnapshot.self, forKey: emergencyKey)
    }

    static func savePay(_ snapshot: PayWidgetSnapshot) {
        save(snapshot, forKey: payKey)
    }

    static func loadPay() -> PayWidgetSnapshot? {
        load(PayWidgetSnapshot.self, forKey: payKey)
    }

    static func saveWARTracker(_ snapshot: WARWidgetSnapshot) {
        save(snapshot, forKey: warTrackerKey)
    }

    static func loadWARTracker() -> WARWidgetSnapshot? {
        load(WARWidgetSnapshot.self, forKey: warTrackerKey)
    }

    private static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(value) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }
}
