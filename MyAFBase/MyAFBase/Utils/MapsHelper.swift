import UIKit

enum MapsHelper {
    static func open(address: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.queryItems = [URLQueryItem(name: "q", value: address)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    static func open(latitude: Double, longitude: Double, label: String? = nil) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.queryItems = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
        ]
        if let label {
            components.queryItems?.append(URLQueryItem(name: "q", value: label))
        }
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    static func open(gate: Gate) {
        if let lat = gate.latitude, let lon = gate.longitude {
            open(latitude: lat, longitude: lon, label: gate.name)
        } else if let address = gate.displayAddress {
            open(address: address)
        }
    }
}
