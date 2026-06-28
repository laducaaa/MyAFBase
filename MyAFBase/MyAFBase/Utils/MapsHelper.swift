import UIKit

enum MapsHelper {
    static func open(address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    static func open(latitude: Double, longitude: Double, label: String? = nil) {
        var urlString = "http://maps.apple.com/?ll=\(latitude),\(longitude)"
        if let label, let encoded = label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "&q=\(encoded)"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    static func open(gate: Gate) {
        if let lat = gate.latitude, let lon = gate.longitude {
            open(latitude: lat, longitude: lon, label: gate.name)
        } else if let address = gate.displayAddress {
            open(address: address)
        }
    }
}
