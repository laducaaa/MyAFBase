import SwiftUI

struct EssentialAFISearchView: View {
    @State private var searchText = ""
    @Environment(\.isSearching) private var isSearching

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredAFIs: [EssentialAFI] {
        EssentialAFIs.filtered(query: searchText)
    }

    private var showsSuggestions: Bool {
        trimmedSearchText.isEmpty && !isSearching
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AssignmentMetrics.sectionSpacing) {
                if showsSuggestions {
                    suggestionChipsSection
                }

                quickAccessSection
            }
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("Essential AFI Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search AFIs and publications"
        )
    }

    private var suggestionChipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try searching for")
                .font(.caption)
                .foregroundStyle(.tertiary)

            AFISuggestionChipLayout(spacing: 8) {
                ForEach(EssentialAFIs.searchSuggestions, id: \.self) { suggestion in
                    AFISuggestionChip(title: suggestion) {
                        searchText = suggestion
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var quickAccessSection: some View {
        if filteredAFIs.isEmpty {
            emptyResultsView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick access")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredAFIs) { afi in
                        AssignmentAFICard(afi: afi)
                    }
                }
            }
        }

        Link(destination: EssentialAFIs.ePublishingIndex) {
            Label("Browse all publications on e-Publishing", systemImage: "books.vertical")
                .labelStyle(AppAccentIconLabelStyle())
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var emptyResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No matching publications")
                .font(.subheadline.weight(.medium))

            Text("Try a different term, pick a suggestion above, or browse the quick access cards.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct AFISuggestionChip: View {
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

private struct AFISuggestionChipLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > 0, currentX + size.width > maxWidth {
                totalWidth = max(totalWidth, currentX - spacing)
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = currentY + rowHeight
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return CGSize(width: totalWidth, height: totalHeight)
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
        EssentialAFISearchView()
    }
}
#endif
