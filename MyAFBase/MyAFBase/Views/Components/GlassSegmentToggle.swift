import SwiftUI

struct GlassSegmentToggle<Option: Hashable>: View {
    enum Layout {
        case compact
        case equalWidth
    }

    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var layout: Layout = .compact

    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var segmentNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segmentButton(option)
            }
        }
        .padding(4)
        .background { trackBackground }
        .overlay { trackStrokeOverlay }
        .modifier(GlassSegmentTrackChrome(colorScheme: colorScheme))
        .shadow(color: trackShadowColor, radius: trackShadowRadius, y: trackShadowY)
    }

    @ViewBuilder
    private var trackBackground: some View {
        if colorScheme == .dark {
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.72))
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        } else {
            Capsule()
                .fill(Color(.tertiarySystemFill))
        }
    }

    @ViewBuilder
    private var trackStrokeOverlay: some View {
        if colorScheme == .light {
            Capsule()
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private func segmentButton(_ option: Option) -> some View {
        let isSelected = selection == option

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selection = option
            }
        } label: {
            Text(label(option))
                .font(ExploreMetrics.segmentFont)
                .foregroundStyle(isSelected ? selectedTextColor : unselectedTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: layout == .equalWidth ? .infinity : nil)
                .frame(minWidth: layout == .compact ? ExploreMetrics.segmentMinWidth : nil)
                .padding(.horizontal, layout == .compact ? ExploreMetrics.segmentHorizontalPadding : 12)
                .padding(.vertical, ExploreMetrics.segmentVerticalPadding)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(selectedPillFill)
                            .shadow(color: selectedPillShadow, radius: 2, y: 1)
                            .matchedGeometryEffect(id: "glassSegmentHighlight", in: segmentNamespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(option))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var selectedTextColor: Color {
        colorScheme == .dark ? .black : .primary
    }

    private var unselectedTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : .secondary
    }

    private var selectedPillFill: Color {
        colorScheme == .dark ? .white : Color(.systemBackground)
    }

    private var selectedPillShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    private var trackShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.06)
    }

    private var trackShadowRadius: CGFloat {
        colorScheme == .dark ? 16 : 4
    }

    private var trackShadowY: CGFloat {
        colorScheme == .dark ? 6 : 2
    }
}

/// Applies the frosted-glass chrome only in dark mode; light mode uses a flat track.
private struct GlassSegmentTrackChrome: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content
        }
    }
}

struct FloatingSegmentToggle: View {
    @Binding var selection: ExploreSegment

    var body: some View {
        GlassSegmentToggle(
            options: Array(ExploreSegment.allCases),
            selection: $selection,
            label: \.rawValue,
            layout: .compact
        )
    }
}

struct ExploreDisplayModeToggle: View {
    @Binding var selection: ExploreDisplayMode
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ExploreDisplayMode.allCases) { mode in
                modeButton(mode)
            }
        }
        .padding(3)
        .background {
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 8, y: 2)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06), lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Explore view mode")
    }

    private func modeButton(_ mode: ExploreDisplayMode) -> some View {
        let isSelected = selection == mode

        return Button {
            withAnimation(.snappy(duration: 0.22)) {
                selection = mode
            }
        } label: {
            Image(systemName: mode.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 36, height: 30)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 2, y: 1)
                            .matchedGeometryEffect(id: "exploreModeSelection", in: selectionNamespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
