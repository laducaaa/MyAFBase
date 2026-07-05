import SwiftData
import SwiftUI

/// The "Reports" screen — pick a date range, browse a summary + the entries
/// in range, then generate copy/share-ready text. This doubles as the
/// month/quarter/year overview since browsing and exporting use the same
/// underlying list.
struct WAROutputView: View {
    let baseID: String

    @Environment(WARTrackerStore.self) private var store
    @Environment(ReadinessTrackerStore.self) private var readinessStore

    @State private var preset: WARDateRangePreset = .thisMonth
    @State private var customStart = WARDateMath.startOfMonth(containing: Date())
    @State private var customEnd = Date()
    @State private var grouping: WAROutputGrouping = .chronological
    @State private var format: WAROutputFormat = .plainText
    @State private var showCopiedToast = false
    @State private var pdfURL: URL?
    @State private var showPDFShare = false

    private var range: ClosedRange<Date> {
        let now = Date()
        switch preset {
        case .thisWeek:
            let start = WARDateMath.startOfWeek(containing: now)
            let end = WARDateMath.endOfDay(WARDateMath.days(from: start, count: 7).last ?? start)
            return start...end
        case .thisMonth:
            return WARDateMath.startOfMonth(containing: now)...WARDateMath.endOfMonth(containing: now)
        case .thisQuarter:
            return WARDateMath.startOfQuarter(containing: now)...WARDateMath.endOfQuarter(containing: now)
        case .thisYear:
            return WARDateMath.startOfYear(containing: now)...WARDateMath.endOfYear(containing: now)
        case .closeoutCycle:
            return closeoutCycleRange(now: now)
        case .custom:
            let start = Calendar.current.startOfDay(for: customStart)
            let end = WARDateMath.endOfDay(customEnd)
            return min(start, end)...max(start, end)
        }
    }

    private func closeoutCycleRange(now: Date) -> ClosedRange<Date> {
        let closeout = readinessStore.tracker(for: baseID).evalCloseoutDue
        guard let closeout else {
            return WARDateMath.startOfYear(containing: now)...WARDateMath.endOfYear(containing: now)
        }
        let start = Calendar.current.date(byAdding: .year, value: -1, to: closeout)
            ?? WARDateMath.startOfYear(containing: now)
        let end = max(closeout, now)
        return min(start, end)...end
    }

    private var entries: [WAREntry] {
        store.entries(for: baseID, in: range)
    }

    private var summary: WAROutputSummary {
        WAROutputBuilder.summary(for: entries)
    }

    private var outputText: String {
        WAROutputBuilder.build(entries: entries, grouping: grouping, format: format)
    }

    var body: some View {
        Form {
            dateRangeSection
            summarySection
            optionsSection
            previewSection
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
            }
        }
        .sheet(isPresented: $showPDFShare) {
            if let pdfURL {
                ActivityShareSheet(items: [pdfURL])
            }
        }
    }

    // MARK: - Sections

    private var dateRangeSection: some View {
        Section("Date Range") {
            Picker("Range", selection: $preset) {
                ForEach(WARDateRangePreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }

            if preset == .custom {
                DatePicker("Start", selection: $customStart, displayedComponents: .date)
                DatePicker("End", selection: $customEnd, displayedComponents: .date)
            } else {
                HStack {
                    Text(WARDateMath.fullRangeLabel(from: range.lowerBound, to: range.upperBound))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            if preset == .closeoutCycle && readinessStore.tracker(for: baseID).evalCloseoutDue == nil {
                Label("Set your EPB/OPB closeout date in Readiness to tailor this range.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            HStack {
                summaryStat(value: "\(summary.totalEntries)", label: summary.totalEntries == 1 ? "Entry" : "Entries")
                Divider().frame(height: 32)
                summaryStat(value: hoursLabel(summary.totalHours), label: "Hours")
            }
            .frame(maxWidth: .infinity)

            if !summary.categoryCounts.isEmpty {
                ForEach(summary.categoryCounts, id: \.category) { item in
                    HStack {
                        Label(item.category.title, systemImage: item.category.systemImage)
                            .foregroundStyle(item.category.tint)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var optionsSection: some View {
        Section("Output") {
            Picker("Group by", selection: $grouping) {
                ForEach(WAROutputGrouping.allCases) { grouping in
                    Text(grouping.title).tag(grouping)
                }
            }
            .pickerStyle(.segmented)

            Picker("Format", selection: $format) {
                ForEach(WAROutputFormat.allCases) { format in
                    Text(format.title).tag(format)
                }
            }
            .pickerStyle(.segmented)

            Text(format.helpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var previewSection: some View {
        Section("Preview") {
            ScrollView {
                Text(outputText)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 260)

            HStack(spacing: 12) {
                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(entries.isEmpty)

                ShareLink(item: outputText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(entries.isEmpty)
            }
            .padding(.top, 4)

            Button {
                exportPDF()
            } label: {
                Label("Export PDF", systemImage: "doc.richtext")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(entries.isEmpty)
            .padding(.top, 4)
        }
    }

    private var copiedToast: some View {
        Text("Copied to clipboard")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85), in: Capsule())
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = outputText
        withAnimation { showCopiedToast = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { showCopiedToast = false }
        }
    }

    private func hoursLabel(_ hours: Double) -> String {
        hours == hours.rounded() ? "\(Int(hours))" : String(format: "%.1f", hours)
    }

    private func exportPDF() {
        let subtitle = "\(grouping.title) · \(WARDateMath.fullRangeLabel(from: range.lowerBound, to: range.upperBound))"
        let data = WARPDFBuilder.makePDF(title: "WAR Tracker Report", subtitle: subtitle, bodyText: outputText)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WARTrackerReport-\(UUID().uuidString).pdf")
        do {
            try data.write(to: url)
            pdfURL = url
            showPDFShare = true
        } catch {
            pdfURL = nil
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WAROutputView(baseID: "keesler")
    }
    .environment(WARTrackerStore(modelContext: ModelContainerFactory.preview().mainContext))
    .environment(ReadinessTrackerStore(modelContext: ModelContainerFactory.preview().mainContext))
}
#endif
