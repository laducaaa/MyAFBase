import SwiftUI

struct PayCalendarView: View {
    @State private var specialPayStore = SpecialPayStore()
    @State private var showAddSpecialPay = false
    @State private var insightsExpanded = false

    private var upcomingEvents: [PayCalendarEvent] {
        PayCalendar.upcomingEvents(specialPays: specialPayStore.entries)
    }

    private var nextEvent: PayCalendarEvent? {
        upcomingEvents.first
    }

    private var payInsights: [PayCalendarInsight] {
        PayCalendar.insights(from: upcomingEvents)
    }

    private var nextLongGap: PayGapInsight? {
        PayCalendar.longGapInsights(in: upcomingEvents).first
    }

    private var additionalInsights: [PayCalendarInsight] {
        guard let nextLongGap else { return payInsights }
        return payInsights.filter { $0.id != "long-\(nextLongGap.id)" }
    }

    private var totalInsightCount: Int {
        payInsights.count
    }

    private var insightsSummary: String {
        if let nextLongGap {
            return "\(nextLongGap.gapDays)-day pay gap · \(totalInsightCount) total"
        }
        let warnings = payInsights.filter { $0.severity == .warning }.count
        if warnings > 0 {
            return "\(warnings) warning\(warnings == 1 ? "" : "s") · \(totalInsightCount) total"
        }
        return "\(totalInsightCount) schedule note\(totalInsightCount == 1 ? "" : "s")"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if let nextEvent {
                    nextPayCard(nextEvent)
                }

                if totalInsightCount > 0 {
                    collapsibleInsightsCard
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
                HomeWidgetSync.publishPayCalendar(specialPays: specialPayStore.entries)
            }
        }
        .onAppear {
            HomeWidgetSync.publishPayCalendar(specialPays: specialPayStore.entries)
        }
        .onChange(of: specialPayStore.entries.count) { _, _ in
            HomeWidgetSync.publishPayCalendar(specialPays: specialPayStore.entries)
        }
    }

    private func nextPayCard(_ event: PayCalendarEvent) -> some View {
        NextPayPeriodCard(event: event)
    }

    private var collapsibleInsightsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    insightsExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Insights")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if !insightsExpanded {
                            Text(insightsSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer(minLength: 8)

                    Text("\(totalInsightCount)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill), in: Capsule())

                    Image(systemName: insightsExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                insightsExpanded
                    ? "Insights, \(totalInsightCount) items, expanded"
                    : "Insights, \(totalInsightCount) items, collapsed"
            )
            .accessibilityHint(insightsExpanded ? "Collapse insights" : "Expand to see all insights")

            if insightsExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    if let nextLongGap {
                        nextLongGapContent(nextLongGap)

                        if !additionalInsights.isEmpty {
                            Divider()
                        }
                    }

                    ForEach(additionalInsights) { insight in
                        PayCalendarInsightRow(insight: insight)

                        if insight.id != additionalInsights.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.top, 14)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func nextLongGapContent(_ gap: PayGapInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Long stretch until next pay")
                        .font(.subheadline.weight(.semibold))
                    Text("\(gap.gapDays) days after \(gap.priorPay.title.lowercased()) on \(gap.priorPay.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gap length")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(gap.gapDays)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.warning)
                        .monospacedDigit()
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next pay")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(gap.nextPay.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Weekend shifts on the 1st and 15th can create gaps longer than two weeks. Plan spending until \(gap.nextPay.date.formatted(date: .abbreviated, time: .omitted)).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

                                    if let gap = PayCalendar.gapAfter(event: event, in: upcomingEvents),
                                       gap.isLongGap || gap.isShortGap,
                                       event.id != events.last?.id {
                                        payGapBadge(gap)
                                    }

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
                                .foregroundStyle(AppTheme.highlight)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Pay dates follow the usual 1st and 15th schedule with weekend adjustments. Confirm exact deposit dates with myPay or your finance office.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(LegalCopy.nonAffiliationOneLine)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle()
    }

    private func payEventRow(_ event: PayCalendarEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.systemImage)
                .foregroundStyle(event.isSpecial ? AppTheme.highlight : AppTheme.accent)
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

    private func payGapBadge(_ gap: PayGapInsight) -> some View {
        HStack(spacing: 8) {
            Image(systemName: gap.isLongGap ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.caption2)
                .foregroundStyle(gap.isLongGap ? AppTheme.warning : AppTheme.accent)

            Text(gap.isLongGap
                 ? "\(gap.gapDays)-day gap until next pay"
                 : "Only \(gap.gapDays) days until next pay")
                .font(.caption.weight(.semibold))
                .foregroundStyle(gap.isLongGap ? AppTheme.warning : .secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(gap.isLongGap ? AppTheme.warning.opacity(0.08) : Color(.secondarySystemGroupedBackground))
    }

    private func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
}

private struct PayCalendarInsightRow: View {
    let insight: PayCalendarInsight

    private var tint: Color {
        switch insight.severity {
        case .warning: AppTheme.warning
        case .info: AppTheme.info
        }
    }

    private var icon: String {
        switch insight.kind {
        case .longGap: "calendar.badge.exclamationmark"
        case .shortGap: "calendar.badge.clock"
        case .weekendAdjustment: "arrow.backward.circle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
