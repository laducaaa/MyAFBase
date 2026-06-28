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
