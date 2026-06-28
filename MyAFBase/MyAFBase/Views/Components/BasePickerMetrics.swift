import SwiftUI

enum BasePickerMetrics {
    static let heroCornerRadius: CGFloat = 16
    static let cardCornerRadius: CGFloat = 14
    static let cardShadowOpacity: Double = 0.08
    static let cardShadowRadius: CGFloat = 8
    static let iconSize: CGFloat = 48
    static let sectionBadgeSize: CGFloat = 28
    static let regionChipHeight: CGFloat = 72
}

extension BaseRegion {
    var pickerIcon: String {
        switch self {
        case .conus: return "globe.americas.fill"
        case .oconus: return "globe"
        }
    }

    var pickerAccent: Color {
        switch self {
        case .conus: return Color(red: 0.22, green: 0.48, blue: 0.86)
        case .oconus: return Color(red: 0.88, green: 0.52, blue: 0.18)
        }
    }
}

extension BaseRegionFilter {
    var pickerIcon: String {
        switch self {
        case .all: return "building.2.fill"
        case .conus: return "globe.americas.fill"
        case .oconus: return "globe"
        }
    }
}

extension View {
    func basePickerCardStyle(isSelected: Bool = false) -> some View {
        background {
            RoundedRectangle(cornerRadius: BasePickerMetrics.cardCornerRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(BasePickerMetrics.cardShadowOpacity),
                    radius: BasePickerMetrics.cardShadowRadius,
                    y: 3
                )
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: BasePickerMetrics.cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.35), lineWidth: 1.5)
            }
        }
    }
}

struct BasePickerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
