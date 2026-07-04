import SwiftUI

/// Polished open-now filter chip for Explore resources.
struct ExploreOpenNowFilter: View {
    @Binding var isOn: Bool
    let openCount: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                statusIndicator

                Image(systemName: "clock.badge.checkmark")
                    .font(.subheadline.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)

                Text("Open now")
                    .font(.subheadline.weight(.semibold))

                if openCount > 0 {
                    Text("\(openCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(countForeground)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(countBackground, in: Capsule())
                }
            }
            .foregroundStyle(labelForeground)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(chipBackground, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(chipBorder, lineWidth: isOn ? 1 : 0.5)
            }
            .shadow(
                color: isOn ? AppTheme.success.opacity(colorScheme == .dark ? 0.22 : 0.14) : .clear,
                radius: 8,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Open now filter on" : "Open now filter off")
        .accessibilityValue(openCount > 0 ? "\(openCount) locations open" : "No open locations")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var statusIndicator: some View {
        ZStack {
            if isOn {
                Circle()
                    .fill(AppTheme.success.opacity(0.28))
                    .frame(width: 16, height: 16)
                    .scaleEffect(isOn ? 1 : 0.6)
            }

            Circle()
                .fill(isOn ? AppTheme.success : Color.secondary.opacity(0.45))
                .frame(width: 8, height: 8)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.68), value: isOn)
    }

    private var chipBackground: some ShapeStyle {
        if isOn {
            AppTheme.success.opacity(colorScheme == .dark ? 0.22 : 0.12)
        } else {
            Color(.tertiarySystemFill)
        }
    }

    private var chipBorder: Color {
        isOn ? AppTheme.success.opacity(colorScheme == .dark ? 0.45 : 0.28) : Color.black.opacity(colorScheme == .dark ? 0.12 : 0.06)
    }

    private var labelForeground: Color {
        isOn ? (colorScheme == .dark ? .white : AppTheme.success) : .primary
    }

    private var countForeground: Color {
        isOn ? (colorScheme == .dark ? .white : AppTheme.success) : .secondary
    }

    private var countBackground: Color {
        isOn ? AppTheme.success.opacity(colorScheme == .dark ? 0.28 : 0.16) : Color(.quaternarySystemFill)
    }
}

/// Staggered fade + bounce when Explore list content changes.
struct ExploreListRevealModifier: ViewModifier {
    let index: Int
    let animationToken: Int

    @State private var revealed = true

    func body(content: Content) -> some View {
        content
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 16)
            .scaleEffect(revealed ? 1 : 0.96, anchor: .top)
            .onAppear {
                guard animationToken > 0 else {
                    revealed = true
                    return
                }
                playReveal(animated: false)
            }
            .onChange(of: animationToken) { _, _ in
                playReveal(animated: true)
            }
    }

    private func playReveal(animated: Bool) {
        revealed = false
        let delay = Double(index) * 0.045
        let animation = Animation.spring(response: 0.46, dampingFraction: 0.74).delay(delay)

        if animated {
            withAnimation(animation) {
                revealed = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(animation) {
                    revealed = true
                }
            }
        }
    }
}

extension View {
    func exploreListReveal(index: Int, animationToken: Int) -> some View {
        modifier(ExploreListRevealModifier(index: index, animationToken: animationToken))
    }
}
