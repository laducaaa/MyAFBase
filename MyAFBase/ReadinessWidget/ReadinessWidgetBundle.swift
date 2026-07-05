import SwiftUI
import WidgetKit

@main
struct ReadinessWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReadinessCountdownWidget()
        WeatherWidget()
        OpenNowWidget()
        EmergencyWidget()
        PayWidget()
        WARQuickLogWidget()
    }
}
