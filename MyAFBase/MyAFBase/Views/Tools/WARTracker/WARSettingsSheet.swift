import SwiftData
import SwiftUI

/// WAR Tracker settings: member type (EPB/OPB terminology), reminders,
/// Face ID lock, and retention.
struct WARSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(WARTrackerStore.self) private var store

    @State private var memberType = WARSettingsStore.memberType
    @State private var dailyNudgeEnabled = WARSettingsStore.dailyNudgeEnabled
    @State private var dailyNudgeHour = WARSettingsStore.dailyNudgeHour
    @State private var weeklyReminderEnabled = WARSettingsStore.weeklyReminderEnabled
    @State private var weeklyReminderWeekday = WARSettingsStore.weeklyReminderWeekday
    @State private var weeklyReminderHour = WARSettingsStore.weeklyReminderHour
    @State private var lockEnabled = WARSettingsStore.lockEnabled
    @State private var autoDeleteEnabled = WARSettingsStore.autoDeleteEnabled
    @State private var autoDeleteAfterYears = WARSettingsStore.autoDeleteAfterYears
    @State private var permissionDenied = false

    private static let weekdaySymbols = Calendar.current.weekdaySymbols

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Member type", selection: $memberType) {
                        ForEach(WARMemberType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Performance report")
                } footer: {
                    Text("Sets whether entries reference the \(memberType.reportAbbreviation) when you map them to a performance factor.")
                }

                Section("Reminders") {
                    Toggle("Daily log nudge", isOn: $dailyNudgeEnabled)
                        .onChange(of: dailyNudgeEnabled, handleDailyNudgeChange)

                    if dailyNudgeEnabled {
                        Stepper(value: $dailyNudgeHour, in: 5...22) {
                            Text("Remind at \(hourLabel(dailyNudgeHour))")
                        }
                        .onChange(of: dailyNudgeHour) { _, newValue in
                            WARSettingsStore.dailyNudgeHour = newValue
                            Task { await WARNotificationService.rescheduleDailyNudge() }
                        }
                    }

                    Toggle("Weekly \"WAR due\" reminder", isOn: $weeklyReminderEnabled)
                        .onChange(of: weeklyReminderEnabled, handleWeeklyReminderChange)

                    if weeklyReminderEnabled {
                        Picker("Day", selection: $weeklyReminderWeekday) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(Self.weekdaySymbols[weekday - 1]).tag(weekday)
                            }
                        }
                        .onChange(of: weeklyReminderWeekday) { _, newValue in
                            WARSettingsStore.weeklyReminderWeekday = newValue
                            Task { await WARNotificationService.rescheduleWeeklyReminder() }
                        }

                        Stepper(value: $weeklyReminderHour, in: 5...22) {
                            Text("Remind at \(hourLabel(weeklyReminderHour))")
                        }
                        .onChange(of: weeklyReminderHour) { _, newValue in
                            WARSettingsStore.weeklyReminderHour = newValue
                            Task { await WARNotificationService.rescheduleWeeklyReminder() }
                        }
                    }

                    if permissionDenied {
                        Label("Notifications are disabled for MyAFBase. Enable them in Settings to use reminders.", systemImage: "bell.slash")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warning)
                    }
                }

                Section {
                    Toggle("Require Face ID / passcode", isOn: $lockEnabled)
                        .onChange(of: lockEnabled) { _, newValue in
                            WARSettingsStore.lockEnabled = newValue
                        }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("When on, WAR Tracker locks whenever the app returns from the background.")
                }

                Section {
                    Toggle("Auto-delete old entries", isOn: $autoDeleteEnabled)
                        .onChange(of: autoDeleteEnabled) { _, newValue in
                            WARSettingsStore.autoDeleteEnabled = newValue
                            if newValue { WARRetentionService.purgeExpiredEntries(store: store) }
                        }

                    if autoDeleteEnabled {
                        Stepper(value: $autoDeleteAfterYears, in: 1...10) {
                            Text("Keep entries for \(autoDeleteAfterYears) \(autoDeleteAfterYears == 1 ? "year" : "years")")
                        }
                        .onChange(of: autoDeleteAfterYears) { _, newValue in
                            WARSettingsStore.autoDeleteAfterYears = newValue
                            WARRetentionService.purgeExpiredEntries(store: store)
                        }
                    }
                } header: {
                    Text("Retention")
                } footer: {
                    Text("Off by default — entries are kept forever unless you opt in. Deletion happens permanently and immediately.")
                }

                Section {
                    LegalDisclaimerCard(text: LegalCopy.warTrackerDisclaimer)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("WAR Tracker Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        WARSettingsStore.memberType = memberType
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func handleDailyNudgeChange(_ oldValue: Bool, _ newValue: Bool) {
        Task {
            let result = await WARNotificationService.setDailyNudgeEnabled(newValue)
            if newValue && !result {
                dailyNudgeEnabled = false
                permissionDenied = true
            }
        }
    }

    private func handleWeeklyReminderChange(_ oldValue: Bool, _ newValue: Bool) {
        Task {
            let result = await WARNotificationService.setWeeklyReminderEnabled(newValue)
            if newValue && !result {
                weeklyReminderEnabled = false
                permissionDenied = true
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

#if DEBUG
#Preview {
    WARSettingsSheet()
        .environment(AppState())
        .environment(WARTrackerStore(modelContext: ModelContainerFactory.preview().mainContext))
}
#endif
