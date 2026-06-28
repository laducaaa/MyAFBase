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

    @Namespace private var segmentNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segmentButton(option)
            }
        }
        .padding(4)
        .background {
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.72))
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
        .glassEffect(.regular, in: .capsule)
        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
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
                .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: layout == .equalWidth ? .infinity : nil)
                .frame(minWidth: layout == .compact ? ExploreMetrics.segmentMinWidth : nil)
                .padding(.horizontal, layout == .compact ? ExploreMetrics.segmentHorizontalPadding : 12)
                .padding(.vertical, ExploreMetrics.segmentVerticalPadding)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.white)
                            .matchedGeometryEffect(id: "glassSegmentHighlight", in: segmentNamespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(option))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

    @Namespace private var highlightNamespace

    private let segmentSize = CGSize(width: 40, height: 32)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ExploreDisplayMode.allCases) { mode in
                segmentButton(for: mode)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(trackFill)
        }
        .overlay {
            Capsule()
                .strokeBorder(trackStroke, lineWidth: 0.5)
        }
    }

    private func segmentButton(for mode: ExploreDisplayMode) -> some View {
        let isSelected = selection == mode

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                selection = mode
            }
        } label: {
            Image(systemName: mode.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? selectedIconColor : unselectedIconColor)
                .frame(width: segmentSize.width, height: segmentSize.height)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(selectedFill)
                            .shadow(color: selectedShadow, radius: 2, y: 1)
                            .matchedGeometryEffect(id: "exploreDisplayModeHighlight", in: highlightNamespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var trackFill: Color {
        colorScheme == .dark
            ? Color(white: 0.18)
            : Color(.tertiarySystemFill)
    }

    private var trackStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    private var selectedFill: Color {
        colorScheme == .dark
            ? Color(white: 0.32)
            : Color(.systemBackground)
    }

    private var selectedShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    private var selectedIconColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var unselectedIconColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : .secondary
    }
}
