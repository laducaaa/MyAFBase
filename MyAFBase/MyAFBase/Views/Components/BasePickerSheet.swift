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
            .background(Color(.systemGroupedBackground))
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
        List {
            Section {
                headerCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if filteredBases.isEmpty {
                Section {
                    emptyResultsView
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            } else {
                ForEach(sectionedBases, id: \.letter) { section in
                    Section {
                        ForEach(section.bases) { base in
                            BasePickerRow(
                                base: base,
                                isSelected: appState.selectedBaseID == base.id,
                                onSelect: { select(base) }
                            )
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        sectionHeader(section.letter)
                    } footer: {
                        if section.letter == sectionedBases.last?.letter {
                            footerLabel
                        }
                    }
                }
            }

            Section {
                moreBasesComingCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(introTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(introMessage)
                        .font(.subheadline)
                        .foregroundStyle(HomeMetrics.heroSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                ForEach(visibleRegionFilters) { filter in
                    regionChip(for: filter)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: BasePickerMetrics.heroCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.13, blue: 0.18),
                            Color(red: 0.18, green: 0.20, blue: 0.26)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        }
    }

    private func regionChip(for filter: BaseRegionFilter) -> some View {
        let isSelected = regionFilter == filter
        let count = count(for: filter)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                regionFilter = filter
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: filter.pickerIcon)
                    .font(.subheadline.weight(.semibold))

                Text(filter.displayName)
                    .font(.caption.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(count)")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(isSelected ? Color(red: 0.11, green: 0.13, blue: 0.18) : Color.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .frame(height: BasePickerMetrics.regionChipHeight)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(filter.displayName), \(count) bases")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func sectionHeader(_ letter: String) -> some View {
        HStack(spacing: 10) {
            Text(letter)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: BasePickerMetrics.sectionBadgeSize, height: BasePickerMetrics.sectionBadgeSize)
                .background(Circle().fill(Color(.label)))

            Rectangle()
                .fill(Color(.separator).opacity(0.35))
                .frame(height: 1)
        }
        .padding(.top, 8)
        .textCase(nil)
    }

    private var moreBasesComingCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "building.2.crop.circle")
                .font(.title3)
                .foregroundStyle(AppTheme.buttonIcon)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("Don't see your base?")
                    .font(.subheadline.weight(.semibold))

                Text("More installations are on the way. We add bases as we verify gates, resources, hours, and newcomer information from official sources.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .basePickerCardStyle()
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
        .padding(.top, 4)
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
