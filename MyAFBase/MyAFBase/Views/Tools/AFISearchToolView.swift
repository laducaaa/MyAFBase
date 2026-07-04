import SwiftUI

/// Standalone Essential AFI search tool — reachable from Home → Tools.
struct AFISearchToolView: View {
    @State private var query = ""
    @Environment(\.isSearching) private var isSearching

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showsSuggestionChips: Bool {
        trimmedQuery.isEmpty && !isSearching
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AssignmentMetrics.sectionSpacing) {
                if showsSuggestionChips {
                    AFISearchSuggestionChips(query: $query)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                AFISearchView(query: $query)
            }
            .padding()
            .animation(.easeInOut(duration: 0.2), value: showsSuggestionChips)
        }
        .appScreenBackground()
        .navigationTitle("Essential AFI Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search AFIs and publications"
        )
    }
}

// MARK: - Suggestion Chips

private struct AFISearchSuggestionChips: View {
    @Binding var query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try searching for")
                .font(.caption)
                .foregroundStyle(.tertiary)

            AFISearchChipLayout(spacing: 8) {
                ForEach(AFISearchCopy.exampleQueries, id: \.self) { suggestion in
                    AFISearchSuggestionChip(title: suggestion) {
                        query = suggestion
                    }
                }
            }
        }
    }
}

private struct AFISearchSuggestionChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.accent.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Wrapping chip layout (shared with suggestion chips).
struct AFISearchChipLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > 0, currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = currentY + rowHeight
        }

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > bounds.minX, currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AFISearchToolView()
    }
    .environment(AFISearchService())
}
#endif
