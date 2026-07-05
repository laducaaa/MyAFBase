import SwiftUI
import SwiftData

/// Identifiable sheet payload so each presentation gets a fresh view with the
/// correct date — `isPresented` alone reuses stale sheet state.
private struct WARQuickAddContext: Identifiable {
    let id = UUID()
    let date: Date
    let locksDate: Bool
}

/// Weekly log view for the WAR Tracker — the primary screen reached from the
/// Home tool tile.
struct WARTrackerToolView: View {
    @Environment(AppState.self) private var appState
    @Environment(WARTrackerStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var weekStart = WARDateMath.startOfWeek(containing: Date())
    @State private var quickAddContext: WARQuickAddContext?
    @State private var editingEntry: WAREntry?
    @State private var showSettings = false
    @State private var showReports = false
    @State private var showAwardDeadlines = false
    @State private var lockState = WARLockState()
    @State private var weekDirection = 1

    private var baseID: String { appState.currentBase?.id ?? "" }

    private var weekDays: [Date] {
        WARDateMath.days(from: weekStart, count: 7)
    }

    private var weekEntryCount: Int {
        guard let end = weekDays.last else { return 0 }
        return store.entryCount(for: baseID, in: weekStart...WARDateMath.endOfDay(end))
    }

    var body: some View {
        Group {
            if lockState.isUnlocked {
                trackerContent
                    .transition(WARMotion.screenTransition)
            } else {
                WARLockedView { await lockState.attemptUnlock() }
                    .transition(WARMotion.screenTransition)
            }
        }
        .animation(WARMotion.spring, value: lockState.isUnlocked)
        .task { await lockState.attemptUnlock() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                lockState.lockIfNeeded()
            }
        }
    }

    private var trackerContent: some View {
        VStack(spacing: 0) {
            weekNavigationHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            List {
                Group {
                    ForEach(weekDays, id: \.timeIntervalSince1970) { day in
                        daySection(for: day)
                    }
                }
                .id(weekStart)
                .transition(WARMotion.weekContentTransition(forward: weekDirection >= 0))

                Section {
                    LegalDisclaimerCard(text: LegalCopy.warTrackerDisclaimer)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(10)
            .scrollContentBackground(.hidden)
        }
        .appScreenBackground()
        .animation(WARMotion.weekChange, value: weekStart)
        .animation(WARMotion.spring, value: store.changeToken)
        .navigationTitle("WAR Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    quickAddContext = WARQuickAddContext(date: Date(), locksDate: false)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Log accomplishment")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showReports = true } label: {
                        Label("Reports", systemImage: "chart.bar.doc.horizontal")
                    }
                    Button { showAwardDeadlines = true } label: {
                        Label("Award Deadlines", systemImage: "flag.checkered")
                    }
                    Button { showSettings = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("WAR Tracker options")
            }
        }
        .sheet(item: $quickAddContext) { context in
            WARQuickAddSheet(
                baseID: baseID,
                defaultDate: context.date,
                locksDate: context.locksDate
            )
        }
        .sheet(item: $editingEntry) { entry in
            WARQuickAddSheet(baseID: baseID, entryToEdit: entry)
        }
        .sheet(isPresented: $showSettings) {
            WARSettingsSheet()
        }
        .sheet(isPresented: $showAwardDeadlines) {
            NavigationStack {
                WARAwardDeadlinesView(baseID: baseID)
            }
        }
        .navigationDestination(isPresented: $showReports) {
            WAROutputView(baseID: baseID)
        }
        .sensoryFeedback(.selection, trigger: weekStart)
    }

    // MARK: - Header

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                changeWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.accent)
            }
            .warPressable()

            Spacer()

            VStack(spacing: 3) {
                Text(weekRangeLabel)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.interpolate)

                HStack(spacing: 4) {
                    Text("\(weekEntryCount)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(weekEntryCount > 0 ? AppTheme.accent : .secondary)

                    Text(weekEntryCount == 1 ? "entry logged" : "entries logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .animation(WARMotion.weekChange, value: weekEntryCount)
            .animation(WARMotion.weekChange, value: weekStart)

            Spacer()

            Button {
                changeWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.accent)
            }
            .warPressable()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .appCardStyle(padding: 14)
    }

    private var weekRangeLabel: String {
        guard let end = weekDays.last else { return "" }
        return WARDateMath.rangeLabel(from: weekStart, to: end)
    }

    private func changeWeek(by delta: Int) {
        weekDirection = delta
        withAnimation(WARMotion.weekChange) {
            weekStart = WARDateMath.addingWeeks(delta, to: weekStart)
        }
    }

    // MARK: - Day sections

    @ViewBuilder
    private func daySection(for day: Date) -> some View {
        let entries = store.entries(for: baseID, on: day)
        let isToday = WARDateMath.isToday(day)
        let isEmpty = entries.isEmpty

        Section {
            if !isEmpty {
                ForEach(entries) { entry in
                    WAREntryRow(entry: entry) {
                        editingEntry = entry
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(WARMotion.spring) {
                                store.delete(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .transition(WARMotion.entryTransition)
                }
            }
        } header: {
            dayHeader(for: day, isToday: isToday, entryCount: entries.count, isEmpty: isEmpty)
        }
    }

    private func dayHeader(for day: Date, isToday: Bool, entryCount: Int, isEmpty: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(WARDateMath.dayLabel(for: day))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isToday ? AppTheme.accent : .primary)

                if isEmpty {
                    Text("Nothing logged")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                } else {
                    Text("\(entryCount) \(entryCount == 1 ? "entry" : "entries")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if isEmpty {
                    quickAddContext = WARQuickAddContext(date: day, locksDate: true)
                }
            }

            Button {
                quickAddContext = WARQuickAddContext(date: day, locksDate: true)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.accent)
            }
            .warPressable(scale: 0.9)
            .accessibilityLabel("Log accomplishment for \(WARDateMath.dayLabel(for: day))")
        }
        .textCase(nil)
        .padding(.top, 2)
        .padding(.bottom, isEmpty ? 2 : 0)
        .animation(WARMotion.spring, value: entryCount)
    }
}

// MARK: - Date helpers

enum WARDateMath {
    static func startOfWeek(containing date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func addingWeeks(_ count: Int, to date: Date, calendar: Calendar = .current) -> Date {
        let shifted = calendar.date(byAdding: .weekOfYear, value: count, to: date) ?? date
        return startOfWeek(containing: shifted, calendar: calendar)
    }

    static func days(from start: Date, count: Int, calendar: Calendar = .current) -> [Date] {
        (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func endOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }

    static func isToday(_ date: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(date)
    }

    static func dayLabel(for date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return isToday(date, calendar: calendar) ? "Today" : formatter.string(from: date)
    }

    static func rangeLabel(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    static func startOfMonth(containing date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func endOfMonth(containing date: Date, calendar: Calendar = .current) -> Date {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return date }
        return calendar.date(byAdding: .second, value: -1, to: interval.end) ?? date
    }

    static func startOfQuarter(containing date: Date, calendar: Calendar = .current) -> Date {
        let month = calendar.component(.month, from: date)
        let quarterStartMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = quarterStartMonth
        components.day = 1
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    static func endOfQuarter(containing date: Date, calendar: Calendar = .current) -> Date {
        let start = startOfQuarter(containing: date, calendar: calendar)
        guard let threeMonthsLater = calendar.date(byAdding: .month, value: 3, to: start) else { return date }
        return calendar.date(byAdding: .second, value: -1, to: threeMonthsLater) ?? date
    }

    static func startOfYear(containing date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .year, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func endOfYear(containing date: Date, calendar: Calendar = .current) -> Date {
        guard let interval = calendar.dateInterval(of: .year, for: date) else { return date }
        return calendar.date(byAdding: .second, value: -1, to: interval.end) ?? date
    }

    static func monthLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    static func fullRangeLabel(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WARTrackerToolView()
    }
    .environment(AppState())
    .environment(WARTrackerStore(modelContext: ModelContainerFactory.preview().mainContext))
}
#endif
