import SwiftUI

private struct ReadinessItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let date: (ReadinessTracker) -> Date?
    let setDate: (ReadinessTracker, Date?) -> Void
    let status: (ReadinessTracker) -> ReadinessStatus

    static let standardItems: [ReadinessItem] = [
        ReadinessItem(
            id: "fitness",
            title: "Fitness test due",
            systemImage: "figure.run",
            date: { $0.fitnessTestDue },
            setDate: { $0.fitnessTestDue = $1 },
            status: { ReadinessStatus.evaluate(dueDate: $0.fitnessTestDue) }
        ),
        ReadinessItem(
            id: "dental",
            title: "Annual dental",
            systemImage: "mouth.fill",
            date: { $0.dentalDue },
            setDate: { $0.dentalDue = $1 },
            status: { ReadinessStatus.evaluate(dueDate: $0.dentalDue) }
        ),
        ReadinessItem(
            id: "eval",
            title: "EPR / OPB closeout",
            systemImage: "doc.text.fill",
            date: { $0.evalCloseoutDue },
            setDate: { $0.evalCloseoutDue = $1 },
            status: { ReadinessStatus.evaluate(dueDate: $0.evalCloseoutDue) }
        ),
        ReadinessItem(
            id: "cac",
            title: "CAC expiration",
            systemImage: "person.crop.rectangle.fill",
            date: { $0.cacExpiration },
            setDate: { $0.cacExpiration = $1 },
            status: { ReadinessStatus.evaluate(dueDate: $0.cacExpiration) }
        ),
        ReadinessItem(
            id: "clearance",
            title: "Clearance renewal",
            systemImage: "lock.shield.fill",
            date: { $0.clearanceRenewal },
            setDate: { $0.clearanceRenewal = $1 },
            status: { ReadinessStatus.evaluate(dueDate: $0.clearanceRenewal) }
        )
    ]
}

struct ReadinessTrackerView: View {
    let baseID: String
    let baseName: String

    @Environment(ReadinessTrackerStore.self) private var readinessTrackerStore
    @State private var tracker: ReadinessTracker?
    @State private var editingItem: ReadinessItem?
    @State private var draftDate = Date()
    @State private var remindersEnabled = ReadinessNotificationService.remindersEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
                .padding(.horizontal, AssignmentMetrics.cardPadding)
                .padding(.top, AssignmentMetrics.cardPadding)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(ReadinessItem.standardItems) { item in
                    if item.id != ReadinessItem.standardItems.first?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                    readinessRow(item)
                }

                Divider()
                    .padding(.leading, 56)

                pcsWindowRow
            }

            footerSection
                .padding(AssignmentMetrics.cardPadding)
        }
        .appCardStyle(padding: 0)
        .onAppear {
            if tracker == nil {
                tracker = readinessTrackerStore.tracker(for: baseID)
            }
            remindersEnabled = ReadinessNotificationService.remindersEnabled
            AppIntentDonations.recordReadinessChecked(baseID: baseID, baseName: baseName)
        }
        .sheet(item: $editingItem) { item in
            readinessDateSheet(for: item)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal readiness")
                        .font(.headline)

                    Text("Track due dates you enter yourself — not connected to official systems.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if let tracker, hasAnyDates(tracker) {
                    ReadinessSummaryBadge(tracker: tracker)
                }
            }
        }
    }

    @ViewBuilder
    private func readinessRow(_ item: ReadinessItem) -> some View {
        if let tracker {
            let status = item.status(tracker)
            let dueDate = item.date(tracker)

            Button {
                editingItem = item
                draftDate = dueDate ?? Date()
            } label: {
                ReadinessTrackerRowLabel(
                    systemImage: item.systemImage,
                    title: item.title,
                    date: dueDate,
                    status: status
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var pcsWindowRow: some View {
        if let tracker {
            let status = ReadinessStatus.evaluatePCSWindow(
                start: tracker.pcsWindowStart,
                end: tracker.pcsWindowEnd
            )

            Button {
                editingItem = pcsWindowItem
                draftDate = tracker.pcsWindowStart ?? Date()
            } label: {
                ReadinessTrackerRowLabel(
                    systemImage: "airplane.departure",
                    title: "PCS window",
                    date: nil,
                    status: status,
                    detail: pcsWindowDetail(start: tracker.pcsWindowStart, end: tracker.pcsWindowEnd)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Toggle(isOn: $remindersEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Readiness reminders")
                        .font(.subheadline.weight(.medium))
                    Text("Local alerts 14, 7, and 1 day before due dates.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: remindersEnabled) { _, enabled in
                Task {
                    let active = await ReadinessNotificationService.setRemindersEnabled(enabled)
                    remindersEnabled = active
                    if let tracker {
                        await ReadinessNotificationService.reschedule(for: tracker, baseName: baseName)
                    }
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 16)
                    .padding(.top, 1)

                Text("Add the Readiness Countdown widget from your Home Screen to see days remaining at a glance.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LegalDisclaimerCard(
                text: "Do not store sensitive personnel or classified information here.",
                style: .compact,
                systemImage: "exclamationmark.shield"
            )
        }
    }

    private func pcsWindowDetail(start: Date?, end: Date?) -> String? {
        guard let start, let end else {
            return "Tap to set start and end dates"
        }
        let formatter = Date.FormatStyle(date: .abbreviated, time: .omitted)
        return "\(start.formatted(formatter)) – \(end.formatted(formatter))"
    }

    private var pcsWindowItem: ReadinessItem {
        ReadinessItem(
            id: "pcs-window",
            title: "PCS window",
            systemImage: "airplane.departure",
            date: { $0.pcsWindowStart },
            setDate: { _, _ in },
            status: { ReadinessStatus.evaluatePCSWindow(start: $0.pcsWindowStart, end: $0.pcsWindowEnd) }
        )
    }

    @ViewBuilder
    private func readinessDateSheet(for item: ReadinessItem) -> some View {
        NavigationStack {
            Form {
                if item.id == "pcs-window" {
                    if let tracker {
                        DatePicker(
                            "Window opens",
                            selection: Binding(
                                get: { tracker.pcsWindowStart ?? Date() },
                                set: { newValue in
                                    tracker.pcsWindowStart = newValue
                                    readinessTrackerStore.save(tracker, baseName: baseName)
                                    Task { await persistReminders(for: tracker) }
                                }
                            ),
                            displayedComponents: .date
                        )

                        DatePicker(
                            "Window closes",
                            selection: Binding(
                                get: { tracker.pcsWindowEnd ?? Date() },
                                set: { newValue in
                                    tracker.pcsWindowEnd = newValue
                                    readinessTrackerStore.save(tracker, baseName: baseName)
                                    Task { await persistReminders(for: tracker) }
                                }
                            ),
                            displayedComponents: .date
                        )
                    }
                } else if let tracker {
                    DatePicker(
                        "Due date",
                        selection: Binding(
                            get: { item.date(tracker) ?? draftDate },
                            set: { newValue in
                                item.setDate(tracker, newValue)
                                readinessTrackerStore.save(tracker, baseName: baseName)
                                Task { await persistReminders(for: tracker) }
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { editingItem = nil }
                }

                if let tracker, item.id != "pcs-window", item.date(tracker) != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            item.setDate(tracker, nil)
                            readinessTrackerStore.save(tracker, baseName: baseName)
                            Task { await persistReminders(for: tracker) }
                            editingItem = nil
                        }
                    }
                }

                if let tracker, item.id == "pcs-window",
                   tracker.pcsWindowStart != nil || tracker.pcsWindowEnd != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            tracker.pcsWindowStart = nil
                            tracker.pcsWindowEnd = nil
                            readinessTrackerStore.save(tracker, baseName: baseName)
                            Task { await persistReminders(for: tracker) }
                            editingItem = nil
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func hasAnyDates(_ tracker: ReadinessTracker) -> Bool {
        tracker.fitnessTestDue != nil ||
            tracker.dentalDue != nil ||
            tracker.evalCloseoutDue != nil ||
            tracker.pcsWindowStart != nil ||
            tracker.pcsWindowEnd != nil ||
            tracker.cacExpiration != nil ||
            tracker.clearanceRenewal != nil
    }

    @MainActor
    private func persistReminders(for tracker: ReadinessTracker) async {
        await ReadinessNotificationService.reschedule(for: tracker, baseName: baseName)
    }
}

// MARK: - Row Components

private struct ReadinessTrackerRowLabel: View {
    let systemImage: String
    let title: String
    let date: Date?
    let status: ReadinessStatus
    var detail: String?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32, height: 32)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(date == nil && status == .notSet ? .tertiary : .secondary)
                } else if let date {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let countdown = daysUntilText(for: date) {
                        Text(countdown)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(status.color)
                    }
                } else {
                    Text("Tap to set a due date")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 8)

            ReadinessStatusPill(status: status)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, AssignmentMetrics.cardPadding)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func daysUntilText(for date: Date) -> String? {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        switch days {
        case ..<0: return "Past due"
        case 0: return "Due today"
        case 1: return "1 day left"
        default: return "\(days) days left"
        }
    }
}

private struct ReadinessSummaryBadge: View {
    let tracker: ReadinessTracker

    private var label: String {
        let statuses = ReadinessItem.standardItems.map { $0.status(tracker) } + [
            ReadinessStatus.evaluatePCSWindow(start: tracker.pcsWindowStart, end: tracker.pcsWindowEnd)
        ]

        if statuses.contains(.overdue) { return "Action needed" }
        if statuses.contains(.dueSoon) || statuses.contains(.windowOpen) { return "Upcoming" }
        return "On track"
    }

    private var color: Color {
        let statuses = ReadinessItem.standardItems.map { $0.status(tracker) } + [
            ReadinessStatus.evaluatePCSWindow(start: tracker.pcsWindowStart, end: tracker.pcsWindowEnd)
        ]

        if statuses.contains(.overdue) { return AppTheme.danger }
        if statuses.contains(.dueSoon) { return AppTheme.warning }
        if statuses.contains(.windowOpen) { return AppTheme.info }
        return AppTheme.success
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private struct ReadinessStatusPill: View {
    let status: ReadinessStatus

    var body: some View {
        Text(status == .notSet ? "Add" : status.label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(status == .notSet ? AppTheme.accent : status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((status == .notSet ? AppTheme.accent : status.color).opacity(0.12))
            .clipShape(Capsule())
    }
}

extension ReadinessItem: Hashable {
    static func == (lhs: ReadinessItem, rhs: ReadinessItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
