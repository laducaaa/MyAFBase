import SwiftUI

/// Shared motion tokens for the WAR Tracker experience.
enum WARMotion {
    static let spring = Animation.spring(response: 0.38, dampingFraction: 0.84)
    static let weekChange = Animation.spring(response: 0.48, dampingFraction: 0.92)
    static let quick = Animation.easeInOut(duration: 0.18)

    static let entryTransition: AnyTransition = .asymmetric(
        insertion: .opacity.combined(with: .move(edge: .top)),
        removal: .opacity.combined(with: .move(edge: .trailing))
    )

    static let screenTransition: AnyTransition = .opacity.combined(with: .scale(scale: 0.98))

    static func weekContentTransition(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(x: forward ? 14 : -14)),
            removal: .opacity.combined(with: .offset(x: forward ? -14 : 14))
        )
    }
}

// MARK: - Reusable modifiers

struct WARPressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(WARMotion.quick, value: configuration.isPressed)
    }
}

extension View {
    func warPressable(scale: CGFloat = 0.96) -> some View {
        buttonStyle(WARPressableButtonStyle(scale: scale))
    }
}
