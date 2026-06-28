import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    @State private var segment: ExploreSegment = .resources
    @State private var displayMode: ExploreDisplayMode = .list
    @State private var resourceCategoryID = ExploreCategory.all.id
    @State private var eventCategoryID = EventExploreCategory.all.id
    @State private var searchText = ""
    @State private var openNowOnly = false

    var body: some View {
        NavigationStack {
            Group {
                if let base = appState.currentBase {
                    exploreContent(for: base)
                } else if appState.isBaseLoading {
                    BaseLoadingView()
                } else {
                    EmptyStateView.noBaseSelected {
                        appState.shouldShowBasePicker = true
                    }
                }
            }
            .navigationTitle(displayMode == .map ? "" : "Explore")
            .navigationBarTitleDisplayMode(displayMode == .map ? .inline : .large)
            .toolbar {
                if appState.currentBase != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        ExploreDisplayModeToggle(selection: $displayMode)
                    }
                }
            }
            .toolbarBackground(displayMode == .map ? .hidden : .automatic, for: .navigationBar)
            .onAppear {
                applyExploreNavigation(appState.consumeExploreNavigation())
            }
            .onChange(of: appState.pendingExploreDestination) { _, destination in
                guard destination != nil else { return }
                applyExploreNavigation(appState.consumeExploreNavigation())
            }
        }
    }

    @ViewBuilder
    private func exploreContent(for base: Base) -> some View {
        if displayMode == .map {
            mapExploreContent(for: base)
        } else {
            listExploreContent(for: base)
        }
    }

    @ViewBuilder
    private func mapExploreContent(for base: Base) -> some View {
        ExploreMapContainerView(
            base: base,
            searchText: searchText
        )
        .ignoresSafeArea(edges: .bottom)
        .searchable(text: $searchText, prompt: "Search places on \(base.name)")
    }

    @ViewBuilder
    private func listExploreContent(for base: Base) -> some View {
        VStack(spacing: 0) {
            ExploreCategoryBar(
                categories: categoryItems,
                selectedID: selectedCategoryID
            )

            if segment == .resources {
                openNowFilter
            }

            listContent(for: base)
        }
        .appScreenBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            listBottomChrome
        }
        .searchable(text: $searchText, prompt: "Search \(base.name)")
        .onChange(of: segment) { _, _ in
            searchText = ""
            openNowOnly = false
        }
    }

    private var listBottomChrome: some View {
        FloatingSegmentToggle(selection: $segment)
            .padding(.horizontal, 48)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(.systemGroupedBackground).opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)
                .offset(y: -24)
                .allowsHitTesting(false)
            }
    }

    @ViewBuilder
    private func listContent(for base: Base) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                switch segment {
                case .resources:
                    if resourceCategoryID == ExploreCategory.gates.id {
                        ForEach(filteredGates(for: base)) { gate in
                            ExploreGateCard(gate: gate, baseID: base.id, baseName: base.name)
                        }
                    } else {
                        ForEach(filteredResources(for: base)) { resource in
                            ExploreResourceCard(resource: resource, baseID: base.id, baseName: base.name)
                        }
                    }
                case .events:
                    ForEach(filteredEvents(for: base)) { event in
                        ExploreEventCard(event: event, baseID: base.id, baseName: base.name)
                    }
                }

                if isEmpty(for: base) {
                    emptyState(for: base)
                        .padding(.top, 32)
                }

                LegalDisclaimerCard(
                    text: LegalCopy.unofficialInformation,
                    style: .compact,
                    systemImage: "info.circle"
                )
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private func applyExploreDestination(_ destination: ExploreDestination?) {
        guard let destination else { return }
        applyExploreNavigation((destination, nil, false))
    }

    private func applyExploreNavigation(_ navigation: (destination: ExploreDestination, categoryID: String?, openNowOnly: Bool)?) {
        guard let navigation else { return }

        switch navigation.destination {
        case .gates:
            segment = .resources
            resourceCategoryID = ExploreCategory.gates.id
        case .resources:
            segment = .resources
            resourceCategoryID = navigation.categoryID ?? ExploreCategory.all.id
        case .events:
            segment = .events
            eventCategoryID = EventExploreCategory.all.id
        }

        searchText = ""
        openNowOnly = navigation.openNowOnly
    }

    @ViewBuilder
    private func emptyState(for base: Base) -> some View {
        if !searchText.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No Results",
                message: "Nothing matches \"\(searchText)\". Try a different search term.",
                style: .card,
                actionTitle: "Clear Search",
                action: { searchText = "" }
            )
        } else if openNowOnly {
            let isGates = resourceCategoryID == ExploreCategory.gates.id
            EmptyStateView(
                systemImage: "clock.badge.checkmark",
                title: "Nothing Open Now",
                message: isGates
                    ? "No gates appear to be open at the moment. Hours are parsed from base data and may not reflect holidays or closures."
                    : "No resources appear to be open at the moment. Hours are parsed from base data and may not reflect holidays or closures.",
                style: .card,
                actionTitle: "Show All",
                action: { openNowOnly = false }
            )
        } else if segment == .events {
            let categoryName = EventExploreCategory(rawValue: eventCategoryID)?.displayName ?? "Events"
            let hasEvents = !base.events.isEmpty
            EmptyStateView(
                systemImage: "calendar",
                title: hasEvents ? "No Matching Events" : "No Events",
                message: hasEvents
                    ? "No \(categoryName.lowercased()) events match your current filters."
                    : "There are no events listed for \(base.name) yet.",
                style: .card,
                actionTitle: eventCategoryID != EventExploreCategory.all.id ? "Show All Events" : nil,
                action: eventCategoryID != EventExploreCategory.all.id ? { eventCategoryID = EventExploreCategory.all.id } : nil
            )
        } else if resourceCategoryID == ExploreCategory.gates.id {
            EmptyStateView(
                systemImage: "door.left.hand.open",
                title: base.gates.isEmpty ? "No Gates" : "No Matching Gates",
                message: base.gates.isEmpty
                    ? "Gate information is not available for \(base.name) yet."
                    : "No gates match your current search.",
                style: .card
            )
        } else if resourceCategoryID == ExploreCategory.all.id {
            EmptyStateView(
                systemImage: "square.grid.2x2",
                title: "No Resources",
                message: "No locations are listed for \(base.name) yet.",
                style: .card
            )
        } else {
            let category = ExploreCategory(rawValue: resourceCategoryID)
            let categoryName = category?.displayName ?? "Resources"
            let categoryCount = resourcesInCategory(base: base, category: category)
            EmptyStateView(
                systemImage: category?.systemImage ?? "square.grid.2x2",
                title: categoryCount == 0 ? "No \(categoryName)" : "No Matching \(categoryName)",
                message: categoryCount == 0
                    ? "No \(categoryName.lowercased()) locations are listed for \(base.name) yet."
                    : "No \(categoryName.lowercased()) locations match your current filters.",
                style: .card,
                actionTitle: "Show All Resources",
                action: { resourceCategoryID = ExploreCategory.all.id }
            )
        }
    }

    private func resourcesInCategory(base: Base, category: ExploreCategory?) -> Int {
        guard let mapped = category?.resourceCategory else {
            return base.resources.count
        }
        return base.resources.filter { $0.category == mapped }.count
    }

    private var openNowFilter: some View {
        Toggle(isOn: $openNowOnly) {
            Label("Open now", systemImage: "clock.badge.checkmark")
                .labelStyle(AppAccentIconLabelStyle())
                .font(.subheadline)
        }
        .toggleStyle(.button)
        .buttonStyle(.bordered)
        .tint(openNowOnly ? .green : .primary)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryItems: [ExploreCategoryItemData] {
        switch segment {
        case .resources:
            return ExploreCategory.resourcesCategories.map(\.itemData)
        case .events:
            return EventExploreCategory.allCases.map(\.itemData)
        }
    }

    private var selectedCategoryID: Binding<String> {
        Binding(
            get: { segment == .resources ? resourceCategoryID : eventCategoryID },
            set: { newValue in
                if segment == .resources {
                    resourceCategoryID = newValue
                } else {
                    eventCategoryID = newValue
                }
            }
        )
    }

    private func isEmpty(for base: Base) -> Bool {
        switch segment {
        case .resources:
            if resourceCategoryID == ExploreCategory.gates.id {
                return filteredGates(for: base).isEmpty
            }
            return filteredResources(for: base).isEmpty
        case .events:
            return filteredEvents(for: base).isEmpty
        }
    }

    private func filteredGates(for base: Base) -> [Gate] {
        base.gates.filter { gate in
            let matchesSearch = searchText.isEmpty ||
                gate.name.localizedCaseInsensitiveContains(searchText) ||
                (gate.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (gate.displayAddress?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesOpenNow = !openNowOnly ||
                ResourceHoursStatus.isOpenNow(ResourceHoursStatus.status(for: gate))

            return matchesSearch && matchesOpenNow
        }
    }

    private func filteredResources(for base: Base) -> [Resource] {
        base.resources.filter { resource in
            let category = ExploreCategory(rawValue: resourceCategoryID)
            let matchesCategory: Bool
            if resourceCategoryID == ExploreCategory.all.id {
                matchesCategory = true
            } else if let mapped = category?.resourceCategory {
                matchesCategory = resource.category == mapped
            } else {
                matchesCategory = true
            }

            let matchesSearch = searchText.isEmpty ||
                resource.name.localizedCaseInsensitiveContains(searchText) ||
                (resource.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (resource.displayAddress?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesOpenNow = !openNowOnly ||
                ResourceHoursStatus.isOpenNow(ResourceHoursStatus.status(for: resource))

            return matchesCategory && matchesSearch && matchesOpenNow
        }
    }

    private func filteredEvents(for base: Base) -> [Event] {
        base.events.filter { event in
            let category = EventExploreCategory(rawValue: eventCategoryID)
            let matchesCategory: Bool
            if eventCategoryID == EventExploreCategory.all.id {
                matchesCategory = true
            } else if let mapped = category?.eventCategory {
                matchesCategory = event.category == mapped
            } else {
                matchesCategory = event.category == nil
            }

            let matchesSearch = searchText.isEmpty ||
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                (event.displayAddress?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                event.description.localizedCaseInsensitiveContains(searchText)

            return matchesCategory && matchesSearch
        }
    }
}
