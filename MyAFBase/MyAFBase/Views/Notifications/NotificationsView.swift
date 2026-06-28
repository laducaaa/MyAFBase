import SwiftUI

struct NotificationsView: View {
    @Environment(AppState.self) private var appState
    @Environment(NotificationDismissalStore.self) private var dismissalStore
    @State private var selectedFilterID = "all"

    private static let filterCategories: [ExploreCategoryItemData] = [
        ExploreCategoryItemData(id: "all", displayName: "All", systemImage: "square.grid.2x2")
    ] + NotificationType.allCases.map {
        ExploreCategoryItemData(
            id: $0.rawValue,
            displayName: $0.displayName,
            systemImage: $0.filterSystemImage
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if let base = appState.currentBase {
                    notificationsContent(for: base)
                } else if appState.isBaseLoading {
                    BaseLoadingView()
                } else {
                    EmptyStateView.noBaseSelected {
                        appState.shouldShowBasePicker = true
                    }
                }
            }
            .appScreenBackground()
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func notificationsContent(for base: Base) -> some View {
        let notifications = filteredNotifications(for: base)

        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                typeFilters

                if notifications.isEmpty {
                    alertsEmptyState(for: base)
                } else {
                    LazyVStack(spacing: AppTheme.cardSpacing) {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification) {
                                dismissalStore.dismiss(baseID: base.id, notificationID: notification.id)
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.screenPadding)
        }
        .toolbar {
            if notifications.count >= 2 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All") {
                        dismissalStore.dismissAll(
                            baseID: base.id,
                            notificationIDs: notifications.map(\.id)
                        )
                    }
                    .appButtonTextForeground()
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    private var typeFilters: some View {
        ExploreCategoryBar(
            categories: Self.filterCategories,
            selectedID: $selectedFilterID
        )
        .padding(.horizontal, -AppTheme.screenPadding)
    }

    @ViewBuilder
    private func alertsEmptyState(for base: Base) -> some View {
        let hasAnyActive = base.currentNotifications.contains {
            $0.isActive && !dismissalStore.isDismissed(baseID: base.id, notificationID: $0.id)
        }

        EmptyStateView(
            systemImage: hasAnyActive ? "line.3.horizontal.decrease.circle" : "bell.slash",
            title: emptyStateTitle(hasAnyActive: hasAnyActive),
            message: emptyStateDescription(hasAnyActive: hasAnyActive),
            style: .card,
            actionTitle: selectedFilterID != "all" ? "Show All Alerts" : nil,
            action: selectedFilterID != "all" ? { selectedFilterID = "all" } : nil
        )
    }

    private func filteredNotifications(for base: Base) -> [NotificationItem] {
        let selectedType = selectedNotificationType

        return base.currentNotifications
            .filter { $0.isActive && !dismissalStore.isDismissed(baseID: base.id, notificationID: $0.id) }
            .filter { selectedType == nil || $0.type == selectedType }
            .sorted { $0.postedAt > $1.postedAt }
    }

    private var selectedNotificationType: NotificationType? {
        guard selectedFilterID != "all" else { return nil }
        return NotificationType(rawValue: selectedFilterID)
    }

    private func emptyStateTitle(hasAnyActive: Bool) -> String {
        if !hasAnyActive {
            return "All Clear"
        }
        return "No Matching Alerts"
    }

    private func emptyStateDescription(hasAnyActive: Bool) -> String {
        if !hasAnyActive {
            return "You're all caught up. There are no active alerts for this base right now."
        }
        if selectedNotificationType != nil {
            return "Try a different alert type or show all alerts."
        }
        return "No alerts match your current filter."
    }
}
