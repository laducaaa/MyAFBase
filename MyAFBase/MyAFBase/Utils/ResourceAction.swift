import UIKit

enum ResourceAction {
    static func perform(for resource: Resource) {
        if let phone = resource.displayPhone {
            call(number: phone)
        } else if let urlString = resource.displayURL, let url = SafeURL.webURL(from: urlString) {
            UIApplication.shared.open(url)
        }
    }

    static func call(number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel:\(digits)") {
            UIApplication.shared.open(url)
        }
    }
}
