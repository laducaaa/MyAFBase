import SwiftUI

struct BaseNavigationToolbar: ViewModifier {
    @Environment(AppState.self) private var appState
    @Binding var showBasePicker: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        showBasePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.brandTealLight)

                            Text(appState.currentBase?.name ?? "Select Base")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)

                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        }
                    }
                    .accessibilityLabel("Change base, currently \(appState.currentBase?.name ?? "none selected")")
                }
            }
    }
}

extension View {
    func baseNavigationToolbar(showBasePicker: Binding<Bool>) -> some View {
        modifier(BaseNavigationToolbar(showBasePicker: showBasePicker))
    }
}
