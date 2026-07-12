import SwiftUI

extension BaseRegion {
    var pickerIcon: String {
        switch self {
        case .conus: return "globe.americas.fill"
        case .oconus: return "globe"
        }
    }

    var pickerAccent: Color {
        switch self {
        case .conus: return AppTheme.brandPrimary
        case .oconus: return AppTheme.brandSecondary
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

struct BasePickerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension View {
    func basePickerRowStyle(isSelected: Bool) -> some View {
        elevatedCardStyle()
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.accent.opacity(0.55), lineWidth: 2)
                }
            }
    }
}
