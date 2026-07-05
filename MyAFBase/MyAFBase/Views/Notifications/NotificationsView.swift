import SwiftUI

struct RemindersView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadinessTrackerStore.self) private var readinessTrackerStore
    @Environment(WARTrackerStore.self) private var warTrackerStore
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
        let readinessReminders = ReadinessReminderBuilder.reminders(from: tracker)
        let awardDeadlines = warTrackerStore.deadlines(for: base.id)
        let hasAnyReminders = !readinessReminders.isEmpty || !awardDeadlines.isEmpty

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

                if !hasAnyReminders {
                    remindersEmptyState()
                } else {
                    if !readinessReminders.isEmpty {
                        reminderSection(title: "Readiness") {
                            ForEach(readinessReminders) { reminder in
                                ReadinessReminderRow(reminder: reminder)
                            }
                        }
                    }

                    if !awardDeadlines.isEmpty {
                        reminderSection(title: "Award Deadlines") {
                            ForEach(awardDeadlines) { deadline in
                                NavigationLink {
                                    WARTrackerToolView()
                                } label: {
                                    WARAwardDeadlineReminderRow(deadline: deadline)
                                }
                                .buttonStyle(.plain)
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
    private func reminderSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            LazyVStack(spacing: AppTheme.cardSpacing) {
                content()
            }
        }
    }

    @ViewBuilder
    private func remindersEmptyState() -> some View {
        EmptyStateView(
            systemImage: "calendar.badge.clock",
            title: "No Reminders Yet",
            message: "Track dental, fitness, evals, and award deadlines in Assignment and WAR Tracker. Your upcoming due dates will show up here.",
            style: .card,
            actionTitle: "Go to Assignment",
            action: { selectedTab = 2 }
        )
    }
}

// Legacy name kept for tab wiring during transition.
typealias NotificationsView = RemindersView
