import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(BookmarkStore.self) private var bookmarkStore
    @Environment(ReadinessTrackerStore.self) private var readinessTrackerStore
    @Environment(NotificationDismissalStore.self) private var dismissalStore
    @Environment(AssignmentProfileStore.self) private var assignmentProfileStore
    @Binding var selectedTab: Int
    @State private var savedCategoryID = HomeSavedCategory.all.id

    private let savedAllLimit = 10

    var body: some View {
        NavigationStack {
            Group {
                if let base = appState.currentBase {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                            homeHeroSection(for: base)

                            HomeAssignmentBanner(baseID: base.id, baseName: base.name)

                            remindersSection(for: base)
                            emergencySection(for: base)
                            toolsSection
                            openNowSection(for: base)
                            savedItemsSection(for: base)
                            legalFooterSection
                        }
                        .padding()
                    }
                    .scrollClipDisabled()
                    .refreshable {
                        await appState.refreshAll()
                    }
                    .appScreenBackground()
                } else if appState.isBaseLoading {
                    BaseLoadingView()
                } else {
                    EmptyStateView.noBaseSelected {
                        appState.shouldShowBasePicker = true
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func homeHeroSection(for base: Base) -> some View {
        let showWeather = appState.shouldShowWeatherInHero
        let weatherCondition = showWeather && appState.displayWeather?.isPlaceholder == false
            ? appState.displayWeather?.condition.themeKey
            : nil

        return WeatherHeroSection(
            base: base,
            showWeather: showWeather,
            weatherCondition: weatherCondition,
            isLoading: appState.isWeatherLoading
        )
        .padding(.top, 16)
        .padding(.bottom, 6)
        .animation(.easeInOut(duration: 0.25), value: appState.isWeatherLoading)
        .animation(.easeInOut(duration: 0.45), value: weatherCondition)
    }

    @ViewBuilder
    private func remindersSection(for base: Base) -> some View {
        let tracker = readinessTrackerStore.tracker(for: base.id)
        let allActive = activeReminders(for: base, tracker: tracker)
        let visible = allActive.prefix(1)

        if let reminder = visible.first {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Reminders",
                    actionTitle: allActive.count > 1 ? "See All" : nil,
                    action: allActive.count > 1 ? { selectedTab = 3 } : nil,
                    secondaryActionTitle: allActive.count >= 2 ? "Clear All" : nil,
                    secondaryAction: allActive.count >= 2 ? {
                        withAnimation(Self.reminderDismissAnimation) {
                            dismissalStore.dismissAll(
                                baseID: base.id,
                                notificationIDs: allActive.map(\.id)
                            )
                        }
                    } : nil
                )

                ReadinessReminderRow(reminder: reminder) {
                    withAnimation(Self.reminderDismissAnimation) {
                        dismissalStore.dismiss(baseID: base.id, notificationID: reminder.id)
                    }
                }
                .transition(Self.reminderRowTransition)
            }
            .animation(Self.reminderDismissAnimation, value: reminder.id)
        }
    }

    private static let reminderDismissAnimation = Animation.spring(response: 0.38, dampingFraction: 0.84)

    private static let reminderRowTransition: AnyTransition = .asymmetric(
        insertion: .opacity.combined(with: .move(edge: .top)),
        removal: .opacity
            .combined(with: .scale(scale: 0.94, anchor: .trailing))
            .combined(with: .move(edge: .trailing))
    )

    private func activeReminders(for base: Base, tracker: ReadinessTracker) -> [ReadinessReminder] {
        ReadinessReminderBuilder.reminders(from: tracker)
            .filter { !dismissalStore.isDismissed(baseID: base.id, notificationID: $0.id) }
    }

    @ViewBuilder
    private func openNowSection(for base: Base) -> some View {
        HomeOpenNowSection(base: base) { category in
            appState.openExplore(.resources, categoryID: category?.id, openNowOnly: true)
            selectedTab = 1
        }
    }

    @ViewBuilder
    private func emergencySection(for base: Base) -> some View {
        if !base.emergencyNumbers.isEmpty {
            EmergencyContactsButton(numbers: base.emergencyNumbers)
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tools")

            NavigationLink {
                PTCalculatorView()
            } label: {
                HomeToolCard(
                    title: "PFRA Score Calculator",
                    subtitle: "Estimate your fitness assessment score",
                    systemImage: "figure.run"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                PFRAGoalPlannerView()
            } label: {
                HomeToolCard(
                    title: "PFRA Goal Planner",
                    subtitle: "What you need to hit your goal",
                    systemImage: "target"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                AFISearchToolView()
            } label: {
                HomeToolCard(
                    title: "Essential AFI Search",
                    subtitle: "Search dress & appearance, leave, fitness, and more",
                    systemImage: "doc.text.magnifyingglass"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LeavePlannerView()
            } label: {
                HomeToolCard(
                    title: "Leave Planner",
                    subtitle: "Check upcoming leave or plan before PCS",
                    systemImage: "calendar.badge.clock"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                PayCalendarView()
            } label: {
                HomeToolCard(
                    title: "Pay Calendar",
                    subtitle: "Mid-month, month-end, and special pays",
                    systemImage: "dollarsign.circle.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func savedItemsSection(for base: Base) -> some View {
        let category = HomeSavedCategory(rawValue: savedCategoryID) ?? .all
        let items = bookmarkStore.resolvedSavedItems(
            for: base,
            category: category,
            limit: category == .all ? savedAllLimit : nil
        )
        let totalSaved = bookmarkStore.savedCount(for: base)

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Saved",
                actionTitle: totalSaved > 0 ? "Explore" : nil,
                action: totalSaved > 0 ? { selectedTab = 1 } : nil
            )

            ExploreCategoryBar(
                categories: HomeSavedCategory.allCases.map(\.itemData),
                selectedID: $savedCategoryID
            )
            .padding(.horizontal, -16)

            if items.isEmpty {
                emptySavedState(for: category)
            } else {
                ForEach(items) { item in
                    savedItemCard(item, base: base)
                }

                if category == .all, totalSaved > savedAllLimit {
                    Text("Showing your \(savedAllLimit) most recent saves. Filter by type to see more.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private func savedItemCard(_ item: ResolvedSavedItem, base: Base) -> some View {
        if let gate = item.gate {
            GateCard(gate: gate, baseID: base.id, baseName: base.name)
        } else if let resource = item.resource {
            ResourceCard(resource: resource, baseID: base.id, baseName: base.name)
        } else if let event = item.event {
            ExploreEventCard(event: event, baseID: base.id, baseName: base.name)
        }
    }

    @ViewBuilder
    private func emptySavedState(for category: HomeSavedCategory) -> some View {
        switch category {
        case .all:
            EmptyStateView.savedItems {
                openExplore(for: .all)
            }
        case .gates:
            EmptyStateView.savedGates {
                openExplore(for: .gates)
            }
        case .resources:
            EmptyStateView.savedResources {
                openExplore(for: .resources)
            }
        case .events:
            EmptyStateView.savedEvents {
                openExplore(for: .events)
            }
        }
    }

    private func openExplore(for category: HomeSavedCategory) {
        appState.openExplore(category.exploreDestination)
        selectedTab = 1
    }

    private var legalFooterSection: some View {
        LegalDisclaimerCard(
            text: LegalCopy.nonAffiliationShort,
            style: .compact,
            systemImage: "building.columns"
        )
        .padding(.top, 4)
    }
}
