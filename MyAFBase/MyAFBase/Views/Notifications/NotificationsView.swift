import SwiftUI

struct RemindersView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadinessTrackerStore.self) private var readinessTrackerStore
    @Binding var selectedTab: Int

    @State private var specialPayStore = SpecialPayStore()

    private var nextPayEvent: PayCalendarEvent? {
        PayCalendar.upcomingEvents(specialPays: specialPayStore.entries).first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let base = appState.currentBase {
                    remindersContent(for: base)
                } else if appState.isBaseLoading {
                    BaseLoadingView()
                } else {
                    EmptyStateView.noBaseSelected {
                        appState.shouldShowBasePicker = true
                    }
                }
            }
            .appScreenBackground()
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func remindersContent(for base: Base) -> some View {
        let tracker = readinessTrackerStore.tracker(for: base.id)
        let reminders = ReadinessReminderBuilder.reminders(from: tracker)

        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if let nextPayEvent {
                    NavigationLink {
                        PayCalendarView()
                    } label: {
                        NextPayPeriodCard(event: nextPayEvent)
                    }
                    .buttonStyle(.plain)
                }

                if reminders.isEmpty {
                    remindersEmptyState()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.title3.weight(.semibold))

                        LazyVStack(spacing: AppTheme.cardSpacing) {
                            ForEach(reminders) { reminder in
                                ReadinessReminderRow(reminder: reminder)
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.screenPadding)
        }
        .onAppear {
            HomeWidgetSync.publishPayCalendar(specialPays: specialPayStore.entries)
        }
    }

    @ViewBuilder
    private func remindersEmptyState() -> some View {
        EmptyStateView(
            systemImage: "calendar.badge.clock",
            title: "No Reminders Yet",
            message: "Track dental, fitness, evals, and more in Assignment. Your upcoming due dates will show up here.",
            style: .card,
            actionTitle: "Go to Assignment",
            action: { selectedTab = 2 }
        )
    }
}

// Legacy name kept for tab wiring during transition.
typealias NotificationsView = RemindersView
