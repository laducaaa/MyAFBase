import Charts
import SwiftUI

struct PFRARecordsView: View {
    @Environment(PFRARecordStore.self) private var recordStore
    @Environment(PFRAProfileStore.self) private var profileStore

    @State private var selectedKind: PFRARecordKind?
    @State private var selectedRecordIDs: Set<UUID> = []
    @State private var showClearAllAlert = false
    @State private var detailRecord: PFRARecord?

    private var allRecords: [PFRARecord] {
        recordStore.allRecords()
    }

    private var filteredRecords: [PFRARecord] {
        guard let selectedKind else { return allRecords }
        return allRecords.filter { $0.kind == selectedKind }
    }

    private var trends: PFRATrendsSummary {
        PFRATrendsSummary(records: filteredRecords)
    }

    private var comparisonRecords: [PFRARecord] {
        let selected = filteredRecords.filter { selectedRecordIDs.contains($0.id) }
        if selected.count >= 2 {
            return Array(selected.sorted { $0.testedAt > $1.testedAt }.prefix(3))
        }
        return Array(filteredRecords.prefix(2))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if allRecords.isEmpty {
                    emptyState
                } else {
                    filterChips

                    PFRATrendsCard(trends: trends)

                    if comparisonRecords.count >= 2 {
                        comparisonCard(records: comparisonRecords)
                    }

                    historySection
                }
            }
            .padding(AppTheme.screenPadding)
        }
        .appScreenBackground()
        .navigationTitle("PFRA Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !allRecords.isEmpty {
                    Button("Clear", role: .destructive) {
                        showClearAllAlert = true
                    }
                }
            }
        }
        .alert("Clear All Records?", isPresented: $showClearAllAlert) {
            Button("Clear All", role: .destructive) {
                selectedRecordIDs.removeAll()
                recordStore.deleteAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every saved PFRA score on this device.")
        }
        .sheet(item: Binding(
            get: { detailRecord.map(PFRARecordSheetItem.init) },
            set: { detailRecord = $0.flatMap { recordStore.record(id: $0.id) } }
        )) { item in
            if let record = recordStore.record(id: item.id) {
                NavigationStack {
                    PFRARecordDetailView(record: record) {
                        loadIntoCalculator(record)
                    } onDelete: {
                        delete(record)
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selectedKind) { _, _ in
            selectedRecordIDs = selectedRecordIDs.filter { id in
                filteredRecords.contains { $0.id == id }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Saved Scores", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Save a score from the PFRA Score Calculator to track progress over time.")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: selectedKind == nil) {
                    selectedKind = nil
                }
                ForEach(PFRARecordKind.allCases) { kind in
                    filterChip(title: kind.title, isSelected: selectedKind == kind, tint: kind.tint) {
                        selectedKind = kind
                    }
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, tint: Color = AppTheme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? tint : Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "History")

            Text(filteredRecords.isEmpty
                 ? "No scores in this filter."
                 : "Tap a row for details. Select up to 3 scores to compare.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(filteredRecords, id: \.persistentModelID) { record in
                PFRARecordHistoryRow(
                    record: record,
                    isSelected: selectedRecordIDs.contains(record.id),
                    onSelect: { toggleSelection(record.id) },
                    onOpen: { detailRecord = record }
                )
            }
        }
    }

    private func comparisonCard(records: [PFRARecord]) -> some View {
        let insights = PFRAComparisonInsights.make(from: records)

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Compare")
                    .font(.headline)
                Spacer()
                Text("\(records.count) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 10) {
                ForEach(records, id: \.persistentModelID) { record in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(shortDate(record.testedAt))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f", record.compositeScore))
                            .font(.title2.weight(.bold).monospacedDigit())
                        Text(record.kind.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(record.kind.tint)
                        Text(record.rating)
                            .font(.caption2)
                            .foregroundStyle(record.passed ? AppTheme.success : AppTheme.warning)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Insights")
                        .font(.subheadline.weight(.semibold))

                    ForEach(insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.highlight)
                                .padding(.top, 2)
                            Text(insight)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.highlight.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(["Body Composition", "Cardio", "Strength", "Core"], id: \.self) { name in
                    comparisonComponentRow(name: name, records: records)
                }
            }
        }
        .appCardStyle(padding: 16)
    }

    private func comparisonComponentRow(name: String, records: [PFRARecord]) -> some View {
        let values = records.map { record in
            record.componentSummaries.first(where: { $0.name == name })?.points ?? 0
        }
        let shortName = name == "Body Composition" ? "Body" : name

        return VStack(alignment: .leading, spacing: 6) {
            Text(shortName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.1f", value))
                            .font(.caption.weight(.semibold).monospacedDigit())
                        GeometryReader { geo in
                            Capsule()
                                .fill(Color.accentColor.opacity(index == 0 ? 1 : 0.45))
                                .frame(width: max(8, geo.size.width * CGFloat(min(value / 60, 1))), height: 6)
                        }
                        .frame(height: 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedRecordIDs.contains(id) {
            selectedRecordIDs.remove(id)
            return
        }
        if selectedRecordIDs.count >= 3, let oldest = filteredRecords.last(where: { selectedRecordIDs.contains($0.id) }) {
            selectedRecordIDs.remove(oldest.id)
        }
        selectedRecordIDs.insert(id)
    }

    private func delete(_ record: PFRARecord) {
        selectedRecordIDs.remove(record.id)
        if detailRecord?.id == record.id {
            detailRecord = nil
        }
        recordStore.delete(record)
    }

    private func loadIntoCalculator(_ record: PFRARecord) {
        profileStore.gender = record.gender
        profileStore.age = record.age
        let totalInches = Int(record.heightInches.rounded())
        profileStore.heightFeet = totalInches / 12
        profileStore.heightInches = totalInches % 12
        profileStore.waistTenths = Int((record.waistInches * 10).rounded())
        profileStore.cardioEvent = record.cardioEvent
        profileStore.strengthEvent = record.strengthEvent
        profileStore.strengthReps = record.strengthReps
        profileStore.coreEvent = record.coreEvent

        switch record.cardioEvent {
        case .twoMileRun:
            let total = Int(record.cardioValue.rounded())
            profileStore.runMinutes = total / 60
            profileStore.runSeconds = total % 60
        case .hamr:
            profileStore.hamrShuttles = Int(record.cardioValue.rounded())
        }

        switch record.coreEvent {
        case .sitUps, .crossLegReverseCrunch:
            profileStore.coreReps = Int(record.coreValue.rounded())
        case .forearmPlank:
            let total = Int(record.coreValue.rounded())
            profileStore.plankMinutes = total / 60
            profileStore.plankSeconds = total % 60
        }

        if let tier = record.targetTier {
            profileStore.targetTier = tier
        }

        detailRecord = nil
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}

// MARK: - Trends

struct PFRATrendsCard: View {
    let trends: PFRATrendsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("COMPOSITE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                if let latest = trends.latestScore {
                    Text(String(format: "%.1f", latest))
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("—")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text(headerDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if trends.chronologicalScores.count >= 2 {
                Chart {
                    RuleMark(y: .value("Pass", PFRAScoring.passComposite))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                    ForEach(Array(trends.chronologicalScores.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                        .symbol {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 7, height: 7)
                        }
                        .symbolSize(36)
                    }
                }
                .chartYScale(domain: scoreDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(trends.chronologicalScores.count, 4))) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: [scoreDomain.lowerBound, PFRAScoring.passComposite, scoreDomain.upperBound]) { value in
                        AxisValueLabel {
                            if let score = value.as(Double.self) {
                                Text(String(format: "%.0f", score))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .chartPlotStyle { plot in
                    plot.frame(maxWidth: .infinity)
                }
                .frame(height: 168)
            } else if trends.recordCount == 1 {
                Text("Save another score to see your trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }

            Divider()

            HStack(spacing: 0) {
                summaryMetric(title: "Best", value: trends.bestScore)
                summaryMetric(title: "Average", value: trends.averageScore)
                summaryMetric(title: "Pass rate", valueText: passRateLabel)
            }

            if trends.recordCount > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Averages")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(componentBars, id: \.label) { bar in
                        HStack(spacing: 10) {
                            Text(bar.label)
                                .font(.subheadline)
                                .frame(width: 64, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))
                                    Capsule()
                                        .fill(Color.accentColor)
                                        .frame(width: max(4, geo.size.width * CGFloat(min(bar.value / 60, 1))))
                                }
                            }
                            .frame(height: 8)
                            Text(String(format: "%.1f", bar.value))
                                .font(.caption.monospacedDigit().weight(.medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .appCardStyle(padding: 18)
    }

    private var headerDetail: String {
        if trends.recordCount == 0 { return "No scores yet" }
        if let delta = trends.deltaFromPrevious {
            let sign = delta >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", delta)) from last · \(trends.recordCount) saved"
        }
        return "\(trends.recordCount) saved"
    }

    private var passRateLabel: String {
        guard let rate = trends.passRate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }

    private var scoreDomain: ClosedRange<Double> {
        let scores = trends.chronologicalScores.map(\.score) + [PFRAScoring.passComposite]
        let minScore = floor((scores.min() ?? 60) / 5) * 5 - 5
        let maxScore = ceil((scores.max() ?? 100) / 5) * 5 + 5
        return minScore...maxScore
    }

    private var componentBars: [(label: String, value: Double)] {
        [
            ("Body", trends.averageBody ?? 0),
            ("Cardio", trends.averageCardio ?? 0),
            ("Strength", trends.averageStrength ?? 0),
            ("Core", trends.averageCore ?? 0)
        ]
    }

    private func summaryMetric(title: String, value: Double? = nil, valueText: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(valueText ?? value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.body.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Comparison insights

enum PFRAComparisonInsights {
    static func make(from records: [PFRARecord]) -> [String] {
        guard records.count >= 2 else { return [] }

        let newest = records[0]
        let previous = records[1]
        var insights: [String] = []

        let compositeDelta = newest.compositeScore - previous.compositeScore
        if abs(compositeDelta) < 0.05 {
            insights.append("Composite is unchanged at \(String(format: "%.1f", newest.compositeScore)).")
        } else if compositeDelta > 0 {
            insights.append("Composite improved by \(String(format: "%.1f", compositeDelta)) points since \(shortDate(previous.testedAt)).")
        } else {
            insights.append("Composite dropped \(String(format: "%.1f", abs(compositeDelta))) points since \(shortDate(previous.testedAt)).")
        }

        let components = ["Body Composition", "Cardio", "Strength", "Core"]
        let deltas: [(name: String, delta: Double)] = components.compactMap { name in
            guard
                let newValue = newest.componentSummaries.first(where: { $0.name == name })?.points,
                let oldValue = previous.componentSummaries.first(where: { $0.name == name })?.points
            else { return nil }
            return (shortName(name), newValue - oldValue)
        }

        if let bestGain = deltas.max(by: { $0.delta < $1.delta }), bestGain.delta > 0.2 {
            insights.append("Biggest gain: \(bestGain.name) (+\(String(format: "%.1f", bestGain.delta))).")
        }

        if let worstDrop = deltas.min(by: { $0.delta < $1.delta }), worstDrop.delta < -0.2 {
            insights.append("Biggest drop: \(worstDrop.name) (\(String(format: "%.1f", worstDrop.delta))).")
        }

        if newest.passed, !previous.passed {
            insights.append("You moved from not passing to passing.")
        } else if !newest.passed, previous.passed {
            insights.append("This score is below the pass standard after a previous pass.")
        }

        if let weakest = newest.componentSummaries.min(by: { $0.points < $1.points }) {
            insights.append("Current focus area: \(shortName(weakest.name)) at \(String(format: "%.1f", weakest.points)) points.")
        }

        return Array(insights.prefix(4))
    }

    private static func shortName(_ name: String) -> String {
        name == "Body Composition" ? "Body" : name
    }

    private static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}

// MARK: - History row

private struct PFRARecordHistoryRow: View {
    let record: PFRARecord
    let isSelected: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppTheme.brandPrimary : Color.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? "Deselect score" : "Select score for comparison")

            Button(action: onOpen) {
                HStack(spacing: 12) {
                    IconBadge(systemImage: record.kind.systemImage, tint: record.kind.tint, size: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.testedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                        Text("\(record.kind.title) · \(record.rating)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1f", record.compositeScore))
                            .font(.title3.weight(.bold).monospacedDigit())
                        Text(record.passed ? "Pass" : "Fail")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(record.passed ? AppTheme.success : AppTheme.warning)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .elevatedCardStyle(background: Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Detail

private struct PFRARecordDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let record: PFRARecord
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(record.kind.title, systemImage: record.kind.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(record.kind.tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(record.kind.tint.opacity(0.12), in: Capsule())
                        Spacer()
                    }

                    Text(String(format: "%.1f", record.compositeScore))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    Text("\(record.rating) · \(record.passed ? "Pass" : "Did not pass")")
                        .font(.subheadline)
                        .foregroundStyle(record.passed ? AppTheme.success : AppTheme.warning)
                    Text(record.testedAt.formatted(date: .complete, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(record.componentSummaries, id: \.name) { component in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(component.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(component.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.1f", component.points))
                                .font(.headline.monospacedDigit())
                            Image(systemName: component.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(component.passed ? AppTheme.success : AppTheme.warning)
                        }
                    }
                }
                .appCardStyle(padding: 14)

                if let note = record.note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    onLoad()
                    dismiss()
                } label: {
                    Text("Load into Calculator")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Text("Delete Record")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(AppTheme.screenPadding)
        }
        .appScreenBackground()
        .navigationTitle("Saved Score")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct PFRARecordSheetItem: Identifiable {
    let id: UUID

    init(record: PFRARecord) {
        id = record.id
    }
}
