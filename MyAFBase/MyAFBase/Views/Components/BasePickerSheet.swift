import SwiftUI

struct BasePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var bases: [BaseIndexEntry] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var regionFilter: BaseRegionFilter = .all

    private var regionFilteredBases: [BaseIndexEntry] {
        bases.filter { regionFilter.matches($0.region) }
    }

    private var filteredBases: [BaseIndexEntry] {
        guard !searchText.isEmpty else { return regionFilteredBases }

        return regionFilteredBases.filter { base in
            base.name.localizedCaseInsensitiveContains(searchText)
                || base.location.localizedCaseInsensitiveContains(searchText)
                || base.wing.localizedCaseInsensitiveContains(searchText)
                || base.region.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sectionedBases: [(letter: String, bases: [BaseIndexEntry])] {
        let grouped = Dictionary(grouping: filteredBases) { base in
            String(base.name.prefix(1)).uppercased()
        }
        return grouped.keys.sorted().map { letter in
            (letter: letter, bases: grouped[letter]!.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if bases.isEmpty {
                    EmptyStateView(
                        systemImage: "building.2",
                        title: "No Bases Available",
                        message: "Base data could not be loaded. Try closing and reopening the app.",
                        style: .prominent
                    )
                } else {
                    baseList
                }
            }
            .appScreenBackground()
            .navigationTitle("Select Base")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name, location, or wing")
            .toolbar {
                if appState.selectedBaseID != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .task {
                bases = await appState.loadBaseIndex()
                isLoading = false
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .interactiveDismissDisabled(appState.selectedBaseID == nil)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading installations...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var baseList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                headerCard

                if filteredBases.isEmpty {
                    emptyResultsView
                } else {
                    baseSections

                    footerLabel
                        .padding(.horizontal, 4)
                }

                moreBasesComingCard

                LegalDisclaimerCard(
                    text: LegalCopy.unofficialInformation,
                    style: .compact,
                    systemImage: "info.circle"
                )
                .padding(.horizontal, 4)
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 8)
        }
    }

    private var baseSections: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
            ForEach(sectionedBases, id: \.letter) { section in
                VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                    sectionHeader(section.letter)

                    VStack(spacing: AppTheme.cardSpacing) {
                        ForEach(section.bases) { base in
                            BasePickerRow(
                                base: base,
                                isSelected: appState.selectedBaseID == base.id,
                                onSelect: { select(base) }
                            )
                        }
                    }
                }
            }
        }
    }

    private var visibleRegionFilters: [BaseRegionFilter] {
        BaseRegionFilter.allCases.filter { filter in
            switch filter {
            case .all, .conus:
                return true
            case .oconus:
                return bases.contains { $0.region == .oconus }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemImage: "building.2.fill", tint: AppTheme.accent, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(introTitle)
                        .font(.title3.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(introMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GlassSegmentToggle(
                options: visibleRegionFilters,
                selection: $regionFilter,
                label: regionFilterLabel,
                layout: .equalWidth
            )
        }
        .appCardStyle()
    }

    private func regionFilterLabel(for filter: BaseRegionFilter) -> String {
        let count = count(for: filter)
        return "\(filter.displayName) (\(count))"
    }

    private func sectionHeader(_ letter: String) -> some View {
        HStack(spacing: 10) {
            Text(letter)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, height: 28)
                .background(AppTheme.accent.opacity(0.12), in: Circle())

            Rectangle()
                .fill(Color(.separator).opacity(0.35))
                .frame(height: 1)
        }
        .padding(.horizontal, 4)
    }

    private var moreBasesComingCard: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(systemImage: "plus.circle.fill", tint: AppTheme.brandSecondary, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text("Don't see your base?")
                    .font(.subheadline.weight(.semibold))

                Text("More installations are on the way. We add bases as we verify gates, resources, hours, and newcomer information from official sources.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCardStyle(padding: 14)
        .accessibilityElement(children: .combine)
    }

    private var footerLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet")
                .font(.caption2)
            Text(footerMessage)
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var emptyResultsView: some View {
        if hasActiveFilters {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No Results",
                message: emptyResultsMessage,
                style: .card,
                actionTitle: "Clear Filters",
                action: clearFilters
            )
        } else {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No Results",
                message: emptyResultsMessage,
                style: .card
            )
        }
    }

    private func count(for filter: BaseRegionFilter) -> Int {
        bases.filter { filter.matches($0.region) }.count
    }

    private var hasActiveFilters: Bool {
        regionFilter != .all || !searchText.isEmpty
    }

    private var emptyResultsMessage: String {
        if !searchText.isEmpty {
            return "No bases match \"\(searchText)\" in \(regionFilter.displayName). Try a different name, wing, or location — or check back later as we add more installations."
        }
        return "No \(regionFilter.displayName) installations found."
    }

    private var footerMessage: String {
        let total = bases.count
        let showing = filteredBases.count
        if regionFilter == .all && searchText.isEmpty {
            return "\(total) bases available · Listed alphabetically"
        }
        return "Showing \(showing) of \(total) bases"
    }

    private var introTitle: String {
        appState.selectedBaseID == nil ? "Welcome to MyAFBase" : "Switch Installation"
    }

    private var introMessage: String {
        appState.selectedBaseID == nil
            ? "Choose your home base to load local resources, alerts, and newcomer information."
            : "Pick a new installation and we'll refresh everything for that location."
    }

    private func clearFilters() {
        searchText = ""
        regionFilter = .all
    }

    private func select(_ base: BaseIndexEntry) {
        appState.beginSelectingBase(id: base.id, region: base.region)
        appState.requestHomeNavigation()
        dismiss()

        Task {
            await appState.loadSelectedBase(id: base.id, region: base.region)
        }
    }
}
