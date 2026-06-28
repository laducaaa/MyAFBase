import UIKit

enum ResourceAction {
    static func perform(for resource: Resource) {
        if let phone = resource.displayPhone {
            call(number: phone)
        } else if let urlString = resource.displayURL {
            var normalized = urlString
            if !normalized.hasPrefix("http") {
                normalized = "https://\(normalized)"
            }
            if let url = URL(string: normalized) {
                UIApplication.shared.open(url)
            }
        }
    }

    static func call(number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel:\(digits)") {
            UIApplication.shared.open(url)
        }
    }
}
