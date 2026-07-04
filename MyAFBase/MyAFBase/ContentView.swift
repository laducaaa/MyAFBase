import SwiftUI
import UIKit
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    private let injectedStores: AppStores?

    @State private var bookmarkStore: BookmarkStore?
    @State private var readinessTrackerStore: ReadinessTrackerStore?
    @State private var checklistStore: ChecklistStore?
    @State private var assignmentProfileStore: AssignmentProfileStore?
    @State private var afiSearchService = AFISearchService()
    @State private var dismissalStore = NotificationDismissalStore()
    @State private var showBasePicker = false
    @State private var showOnboarding = false
    @State private var selectedTab = 0

    init(stores: AppStores? = nil) {
        self.injectedStores = stores
    }

    var body: some View {
        Group {
            if let stores = resolvedStores {
                mainTabInterface(stores: stores)
            } else {
                ProgressView()
            }
        }
        .environment(afiSearchService)
        .task {
            guard injectedStores == nil, bookmarkStore == nil else { return }
            let stores = AppStores(modelContext: modelContext)
            bookmarkStore = stores.bookmarkStore
            readinessTrackerStore = stores.readinessTrackerStore
            checklistStore = stores.checklistStore
            assignmentProfileStore = stores.assignmentProfileStore
        }
        .task {
            // Warm the AFI search index at launch so it's usually ready before the
            // user opens Essential AFI Search from Home.
            guard !AppRuntime.isPreview else { return }
            await afiSearchService.prepareIndexIfNeeded()
        }
    }

    private var resolvedStores: AppStores? {
        if let injectedStores {
            return injectedStores
        }

        guard let bookmarkStore,
              let readinessTrackerStore,
              let checklistStore,
              let assignmentProfileStore else {
            return nil
        }

        return AppStores(
            bookmarkStore: bookmarkStore,
            readinessTrackerStore: readinessTrackerStore,
            checklistStore: checklistStore,
            assignmentProfileStore: assignmentProfileStore
        )
    }

    @ViewBuilder
    private func mainTabInterface(stores: AppStores) -> some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ExploreView()
                .tabItem { Label("Explore", systemImage: "magnifyingglass") }
                .tag(1)

            AssignmentView()
                .tabItem { Label("Assignment", systemImage: "suitcase.fill") }
                .tag(2)

            RemindersView(selectedTab: $selectedTab)
                .tabItem { Label("Reminders", systemImage: "calendar.badge.clock") }
                .tag(3)

            MenuView(showBasePicker: $showBasePicker)
                .tabItem { Label("Menu", systemImage: "line.3.horizontal") }
                .tag(4)
        }
        .tint(AppTheme.accent)
        .environment(stores.bookmarkStore)
        .environment(stores.readinessTrackerStore)
        .environment(stores.checklistStore)
        .environment(stores.assignmentProfileStore)
        .environment(dismissalStore)
        .task {
            await syncReadinessNotifications(using: stores)
            await syncReadinessWidget(using: stores)
            await syncHomeWidgets(using: stores)
            await appState.syncRemoteBaseData()
            HomeWidgetSync.publishPayCalendar()
        }
        .onChange(of: appState.currentBase?.id) { _, _ in
            Task { await syncHomeWidgets(using: stores) }
        }
        .onChange(of: stores.bookmarkStore.changeToken) { _, _ in
            Task { await syncHomeWidgets(using: stores) }
        }
        .baseNavigationToolbar(showBasePicker: $showBasePicker)
        .sheet(isPresented: $showBasePicker) {
            BasePickerSheet()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                appState.completeOnboarding()
                showOnboarding = false
                if appState.shouldShowBasePicker {
                    showBasePicker = true
                    appState.shouldShowBasePicker = false
                }
            }
        }
        .onChange(of: appState.shouldShowOnboarding) { _, shouldShow in
            if shouldShow {
                showOnboarding = true
            }
        }
        .onChange(of: appState.shouldShowBasePicker) { _, shouldShow in
            if shouldShow {
                showBasePicker = true
                appState.shouldShowBasePicker = false
            }
        }
        .onChange(of: appState.pendingHomeNavigation) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = 0
                appState.pendingHomeNavigation = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppIntentNotifications.didSwitchBase)) { notification in
            guard let baseID = notification.userInfo?[AppIntentNotifications.baseIDKey] as? String else { return }
            guard appState.selectedBaseID != baseID else { return }
            Task { await appState.selectBase(id: baseID) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard let baseID = AppIntentBaseSelection.selectedBaseID(),
                  appState.selectedBaseID != baseID else { return }
            Task { await appState.selectBase(id: baseID) }
        }
        .onAppear {
            if appState.shouldShowOnboarding {
                showOnboarding = true
            } else if appState.shouldShowBasePicker {
                showBasePicker = true
            }
        }
    }

    @MainActor
    private func syncReadinessNotifications(using stores: AppStores) async {
        guard ReadinessNotificationService.remindersEnabled else { return }

        await ReadinessNotificationService.rescheduleAll(stores.readinessTrackerStore.allTrackers()) { baseID in
            if appState.currentBase?.id == baseID {
                return appState.currentBase?.name ?? "your base"
            }
            return baseID
        }
    }

    @MainActor
    private func syncHomeWidgets(using stores: AppStores) async {
        guard let base = appState.currentBase else { return }
        let savedItems = stores.bookmarkStore.resolvedSavedItems(for: base, category: .all)
        HomeWidgetSync.publishOpenNow(base: base, savedItems: savedItems)
        HomeWidgetSync.publishEmergency(base: base)
    }

    @MainActor
    private func syncReadinessWidget(using stores: AppStores) async {
        guard let base = appState.currentBase else { return }
        let tracker = stores.readinessTrackerStore.tracker(for: base.id)
        ReadinessWidgetSync.publish(tracker: tracker, baseName: base.name)
    }
}

#if DEBUG
#Preview {
    ContentViewPreviewHost()
}
#endif
