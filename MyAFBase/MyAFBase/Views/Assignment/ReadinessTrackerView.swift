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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Personal Readiness", systemImage: "calendar.badge.clock")
                    .font(.headline)

                Spacer()

                if let tracker, hasAnyDates(tracker) {
                    Text(summaryLabel(for: tracker))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(summaryColor(for: tracker))
                }
            }

            VStack(spacing: 0) {
                ForEach(ReadinessItem.standardItems) { item in
                    if item.id != ReadinessItem.standardItems.first?.id {
                        Divider()
                            .padding(.leading, 36)
                    }
                    readinessRow(item)
                }

                Divider()
                    .padding(.leading, 36)

                pcsWindowRow
            }

            Toggle(isOn: $remindersEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Readiness reminders")
                        .font(.subheadline.weight(.medium))
                    Text("Local alerts 14, 7, and 1 day before due dates.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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

            Text("Track due dates you enter yourself. Not connected to official systems.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text("Add the Readiness Countdown widget from your Home Screen to see days remaining at a glance.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(AssignmentMetrics.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AssignmentMetrics.cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(AssignmentMetrics.cardShadowOpacity), radius: 6, y: 2)
        .onAppear {
            if tracker == nil {
                tracker = readinessTrackerStore.tracker(for: baseID)
            }
            remindersEnabled = ReadinessNotificationService.remindersEnabled
        }
        .sheet(item: $editingItem) { item in
            readinessDateSheet(for: item)
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
                HStack(spacing: 12) {
                    Image(systemName: item.systemImage)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        if let dueDate {
                            Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    ReadinessStatusPill(status: status)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
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
                HStack(spacing: 12) {
                    Image(systemName: "airplane.departure")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PCS window")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        if let start = tracker.pcsWindowStart, let end = tracker.pcsWindowEnd {
                            Text("\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Set start and end dates")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    ReadinessStatusPill(status: status)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
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
        .presentationDetents([.medium])
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

    private func summaryLabel(for tracker: ReadinessTracker) -> String {
        let statuses = ReadinessItem.standardItems.map { $0.status(tracker) } + [
            ReadinessStatus.evaluatePCSWindow(start: tracker.pcsWindowStart, end: tracker.pcsWindowEnd)
        ]

        if statuses.contains(.overdue) {
            return "Action needed"
        }
        if statuses.contains(.dueSoon) || statuses.contains(.windowOpen) {
            return "Upcoming"
        }
        return "On track"
    }

    private func summaryColor(for tracker: ReadinessTracker) -> Color {
        let statuses = ReadinessItem.standardItems.map { $0.status(tracker) } + [
            ReadinessStatus.evaluatePCSWindow(start: tracker.pcsWindowStart, end: tracker.pcsWindowEnd)
        ]

        if statuses.contains(.overdue) { return .red }
        if statuses.contains(.dueSoon) || statuses.contains(.windowOpen) { return .orange }
        return .green
    }

    @MainActor
    private func persistReminders(for tracker: ReadinessTracker) async {
        await ReadinessNotificationService.reschedule(for: tracker, baseName: baseName)
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

private struct ReadinessStatusPill: View {
    let status: ReadinessStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.12))
            .clipShape(Capsule())
    }
}
