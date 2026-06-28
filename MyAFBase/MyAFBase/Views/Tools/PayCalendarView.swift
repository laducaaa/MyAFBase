import SwiftUI

struct PayCalendarView: View {
    @State private var specialPayStore = SpecialPayStore()
    @State private var showAddSpecialPay = false

    private var upcomingEvents: [PayCalendarEvent] {
        PayCalendar.upcomingEvents(specialPays: specialPayStore.entries)
    }

    private var nextEvent: PayCalendarEvent? {
        upcomingEvents.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if let nextEvent {
                    nextPayCard(nextEvent)
                }

                regularPayInfoCard
                upcomingSection
                specialPaySection
                disclaimerCard
            }
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("Pay Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSpecialPay = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add special pay")
            }
        }
        .sheet(isPresented: $showAddSpecialPay) {
            AddSpecialPaySheet { entry in
                specialPayStore.add(entry)
            }
        }
    }

    private func nextPayCard(_ event: PayCalendarEvent) -> some View {
        let days = PayCalendar.daysUntil(event.date)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Next pay")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: event.systemImage)
                    .font(.title2)
                    .foregroundStyle(event.isSpecial ? .orange : AppTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.title3.weight(.bold))

                    Text(event.date.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(days)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                    Text(days == 1 ? "day" : "days")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .appCardStyle()
    }

    private var regularPayInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Regular pay schedule")
                .font(.subheadline.weight(.semibold))

            ForEach(PayEventKind.allCases) { kind in
                HStack(spacing: 12) {
                    Image(systemName: kind.systemImage)
                        .foregroundStyle(AppTheme.buttonIcon)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.title)
                            .font(.subheadline.weight(.semibold))
                        Text(kind.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .appCardStyle()
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming dates")
                .font(.subheadline.weight(.semibold))

            let grouped = Dictionary(grouping: upcomingEvents.prefix(12)) { event in
                Calendar.current.component(.month, from: event.date)
            }
            let sortedMonths = grouped.keys.sorted()

            if sortedMonths.isEmpty {
                Text("No upcoming pay dates found.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .appCardStyle()
            } else {
                ForEach(sortedMonths, id: \.self) { month in
                    if let events = grouped[month] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(monthTitle(for: events[0].date))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                ForEach(events) { event in
                                    payEventRow(event)
                                    if event.id != events.last?.id {
                                        Divider().padding(.leading, 44)
                                    }
                                }
                            }
                            .appCardStyle(padding: 0)
                        }
                    }
                }
            }
        }
    }

    private var specialPaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Special pays")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Add") { showAddSpecialPay = true }
                    .font(.caption.weight(.semibold))
            }

            if specialPayStore.entries.isEmpty {
                Text("Track bonuses, incentive pays, or other one-time deposits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .appCardStyle()
            } else {
                VStack(spacing: 0) {
                    ForEach(specialPayStore.entries) { entry in
                        HStack(spacing: 12) {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                specialPayStore.remove(id: entry.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if entry.id != specialPayStore.entries.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .appCardStyle(padding: 0)
            }
        }
    }

    private var disclaimerCard: some View {
        Text("Pay dates follow the usual 1st and 15th schedule with weekend adjustments. Confirm exact deposit dates with myPay or your finance office.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .appCardStyle()
    }

    private func payEventRow(_ event: PayCalendarEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.systemImage)
                .foregroundStyle(event.isSpecial ? .orange : AppTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                Text(event.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let days = PayCalendar.daysUntil(event.date)
            Text(days == 0 ? "Today" : "\(days)d")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
}

private struct AddSpecialPaySheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var notes = ""

    let onSave: (SpecialPayEntry) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Special pay") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    DatePicker("Expected date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Special Pay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = SpecialPayEntry(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            date: date,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
