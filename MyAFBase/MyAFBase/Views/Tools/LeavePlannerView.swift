import SwiftUI

private enum LeavePlannerMode: String, CaseIterable, Identifiable {
    case upcoming
    case pcs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upcoming: "Upcoming Leave"
        case .pcs: "PCS Planning"
        }
    }

    var subtitle: String {
        switch self {
        case .upcoming: "Will you have enough leave by your dates?"
        case .pcs: "How much to use before you PCS?"
        }
    }

    var systemImage: String {
        switch self {
        case .upcoming: "airplane.departure"
        case .pcs: "suitcase.fill"
        }
    }
}

struct LeavePlannerView: View {
    @State private var mode: LeavePlannerMode = .upcoming
    @State private var currentBalanceText = "30"
    @State private var maxBalanceAtPCSText = "60"
    @State private var specialLeaveText = "0"
    @State private var accrualRateText = "2.5"
    @State private var leaveStartDate = Calendar.current.startOfDay(for: Date())
    @State private var leaveEndDate = Calendar.current.startOfDay(for: Date())
    @State private var pcsDate = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
    @State private var hasSpecialLeaveExpiration = false
    @State private var specialLeaveExpires = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
    @FocusState private var focusedField: LeaveInputField?

    private var currentBalance: Double {
        parsedDays(from: currentBalanceText) ?? 0
    }

    private var maxBalanceAtPCS: Double {
        parsedDays(from: maxBalanceAtPCSText) ?? LeavePlanner.defaultMaxBalanceAtPCS
    }

    private var specialLeaveBalance: Double {
        parsedDays(from: specialLeaveText) ?? 0
    }

    private var accrualPerMonth: Double {
        parsedDays(from: accrualRateText) ?? LeavePlanner.defaultAccrualPerMonth
    }

    private var leaveDayCount: Int? {
        LeavePlanner.leaveDays(from: leaveStartDate, to: leaveEndDate)
    }

    private var tripCoverage: LeaveTripCoverageResult? {
        guard let leaveDayCount, leaveDayCount > 0 else { return nil }

        return LeavePlanner.evaluateTripCoverage(
            currentBalance: currentBalance,
            leaveStartDate: leaveStartDate,
            leaveEndDate: leaveEndDate,
            accrualPerMonth: accrualPerMonth
        )
    }

    private var plan: LeavePlanResult? {
        LeavePlanner.plan(
            currentBalance: currentBalance,
            pcsDate: pcsDate,
            maxBalanceAtPCS: maxBalanceAtPCS,
            specialLeaveBalance: specialLeaveBalance,
            specialLeaveExpires: hasSpecialLeaveExpiration ? specialLeaveExpires : nil
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                modePicker

                switch mode {
                case .upcoming:
                    upcomingSection
                case .pcs:
                    pcsSection
                }

                disclaimerCard
            }
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("Leave Planner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    // MARK: - Mode

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you planning?")
                .font(.subheadline.weight(.semibold))

            GlassSegmentToggle(
                options: LeavePlannerMode.allCases,
                selection: $mode,
                label: { $0.title },
                layout: .equalWidth
            )

            Label(mode.subtitle, systemImage: mode.systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCardStyle(padding: 16)
    }

    // MARK: - Upcoming leave

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            upcomingInputsCard

            if let coverage = tripCoverage, coverage.isValidRange {
                upcomingVerdictCard(coverage)
            }
        }
    }

    private var upcomingInputsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            LeavePlannerSectionHeader(
                title: "Your dates",
                subtitle: "Enter your balance, leave period, and accrual rate."
            )

            VStack(alignment: .leading, spacing: 16) {
                LeavePlannerSubsection(
                    title: "Starting balance",
                    caption: "What you have in the bank today."
                ) {
                    balanceField(showsLabel: false)
                }

                LeavePlannerSubsection(
                    title: "Leave period",
                    caption: "Start and end dates — both days count toward your total."
                ) {
                    LeaveDateRangeCard(
                        startDate: $leaveStartDate,
                        endDate: $leaveEndDate,
                        dayCount: leaveDayCount
                    )
                    .onChange(of: leaveStartDate) { _, newStart in
                        if leaveEndDate < newStart {
                            leaveEndDate = newStart
                        }
                    }
                }

                LeavePlannerSubsection(
                    title: "Accrual",
                    caption: "How fast you earn leave before your trip starts."
                ) {
                    LeaveNumberFieldView(
                        label: "Leave accrual rate",
                        text: $accrualRateText,
                        field: .accrualRate,
                        focusedField: $focusedField,
                        showsLabel: false,
                        detail: "Active duty usually earns 2.5 days per month",
                        maxValue: 10,
                        unitLabel: "days/mo"
                    )
                }
            }
        }
        .appCardStyle(padding: 20)
    }

    private func upcomingVerdictCard(_ coverage: LeaveTripCoverageResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LeaveVerdictHeader(
                isPositive: coverage.isCovered,
                title: coverage.isCovered ? "You should have enough leave" : "You may come up short",
                subtitle: "\(shortDate(coverage.leaveStartDate)) – \(shortDate(coverage.leaveEndDate)) · \(daysLabel(coverage.leaveDays))"
            )

            LeaveComparisonRow(
                items: [
                    .init(label: "Balance now", value: coverage.currentBalance, emphasis: .normal),
                    .init(label: "By start date", value: coverage.projectedBalance, emphasis: .highlight),
                    .init(label: "You need", value: coverage.leaveDays, emphasis: .normal)
                ]
            )

            LeaveCoverageBar(
                current: coverage.currentBalance,
                projected: coverage.projectedBalance,
                required: coverage.leaveDays
            )

            if coverage.isCovered {
                if coverage.spareDays > 0.05 {
                    LeaveInsightRow(
                        systemImage: "checkmark.circle.fill",
                        tint: .green,
                        text: "About \(daysLabel(coverage.spareDays)) left over after this leave."
                    )
                }
            } else {
                LeaveInsightRow(
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .orange,
                    text: "You may be short by \(daysLabel(coverage.shortfall)) when leave starts."
                )
            }

            if coverage.accruedByLeave > 0 {
                LeaveInsightRow(
                    systemImage: "calendar.badge.plus",
                    tint: AppTheme.accent,
                    text: "You'll accrue about \(daysLabel(coverage.accruedByLeave)) before leave starts at \(rateLabel(accrualPerMonth))."
                )
            }

            if coverage.daysUntilLeave > 0 {
                LeaveInsightRow(
                    systemImage: "clock",
                    tint: .secondary,
                    text: "Leave starts in \(coverage.daysUntilLeave) day\(coverage.daysUntilLeave == 1 ? "" : "s")."
                )
            }
        }
        .appCardStyle(padding: 20)
    }

    // MARK: - PCS

    private var daysUntilPCS: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let pcs = calendar.startOfDay(for: pcsDate)
        return max(0, calendar.dateComponents([.day], from: today, to: pcs).day ?? 0)
    }

    private var pcsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            pcsInputsCard

            if let plan {
                pcsVerdictCard(plan)

                if plan.needsUsagePlan, !plan.milestones.isEmpty {
                    pcsMilestonesCard(plan)
                }

                if let guidance = pcsGuidanceNotes(from: plan.notes) {
                    LeaveInsightCard(notes: guidance)
                }
            }
        }
    }

    private var pcsInputsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            LeavePlannerSectionHeader(
                title: "PCS details",
                subtitle: "Enter your balance, move date, planning cap, and any special leave."
            )

            VStack(alignment: .leading, spacing: 16) {
                LeavePlannerSubsection(
                    title: "Starting balance",
                    caption: "What you have in the bank today."
                ) {
                    balanceField(showsLabel: false)
                }

                LeavePlannerSubsection(
                    title: "PCS move",
                    caption: "When you report to your next assignment."
                ) {
                    LeavePCSTimelineCard(
                        pcsDate: $pcsDate,
                        daysUntilPCS: daysUntilPCS
                    )
                }

                LeavePlannerSubsection(
                    title: "Planning cap",
                    caption: "Target max balance at PCS — often 60 days."
                ) {
                    LeaveNumberFieldView(
                        label: "Max balance at PCS",
                        text: $maxBalanceAtPCSText,
                        field: .maxBalanceAtPCS,
                        focusedField: $focusedField,
                        showsLabel: false,
                        detail: "Confirm with your unit CSS",
                        maxValue: 120
                    )
                }

                LeavePlannerSubsection(
                    title: "Special leave",
                    caption: "RLA, parental, or other special categories on the books."
                ) {
                    LeaveSpecialLeaveCard(
                        balanceText: $specialLeaveText,
                        hasExpiration: $hasSpecialLeaveExpiration,
                        expiresDate: $specialLeaveExpires,
                        focusedField: $focusedField
                    )
                }
            }
        }
        .appCardStyle(padding: 20)
    }

    private func pcsVerdictCard(_ plan: LeavePlanResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LeaveVerdictHeader(
                isPositive: !plan.needsUsagePlan,
                title: plan.needsUsagePlan ? "Plan to use leave before PCS" : "You're within your PCS cap",
                subtitle: "\(plan.daysUntilPCS) days until PCS · balance \(daysLabel(plan.currentBalance))"
            )

            if plan.needsUsagePlan {
                LeaveComparisonRow(
                    items: [
                        .init(label: "Must use", value: plan.excessLeave, emphasis: .highlight),
                        .init(label: "Per month", value: plan.daysPerMonthToUse, emphasis: .normal),
                        .init(label: "Per week", value: plan.daysPerWeekToUse, emphasis: .normal)
                    ]
                )

                LeaveInsightRow(
                    systemImage: "flame.fill",
                    tint: .orange,
                    text: "Use about \(daysLabel(plan.excessLeave)) before PCS to stay at or below \(daysLabel(plan.maxBalanceAtPCS))."
                )
            } else {
                LeaveInsightRow(
                    systemImage: "checkmark.circle.fill",
                    tint: .green,
                    text: "No excess leave above your \(daysLabel(plan.maxBalanceAtPCS)) planning cap."
                )
            }
        }
        .appCardStyle(padding: 20)
    }

    private func pcsMilestonesCard(_ plan: LeavePlanResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            LeavePlannerSectionHeader(
                title: "Suggested pace",
                subtitle: "Spread usage so you're on track before PCS."
            )

            ForEach(plan.milestones) { milestone in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(milestone.title)
                            .font(.subheadline.weight(.semibold))
                        Text(milestone.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(shortDate(milestone.date))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .appCardStyle(padding: 20)
    }

    // MARK: - Shared

    private func balanceField(showsLabel: Bool = true) -> some View {
        LeaveNumberFieldView(
            label: "Current leave balance",
            text: $currentBalanceText,
            field: .currentBalance,
            focusedField: $focusedField,
            showsLabel: showsLabel,
            maxValue: 120
        )
    }

    private var disclaimerCard: some View {
        Label {
            Text("Unofficial planning aid only. Rules vary by status and command — confirm balances, caps, and sell-back with your unit CSS.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "info.circle")
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(padding: 14, background: Color(.secondarySystemGroupedBackground))
    }

    private func pcsGuidanceNotes(from notes: [String]) -> [String]? {
        let filtered = notes.filter {
            !$0.localizedCaseInsensitiveContains("unofficial estimate")
                && !$0.localizedCaseInsensitiveContains("confirm with your unit css")
                && !$0.localizedCaseInsensitiveContains("at or below the")
                && !$0.localizedCaseInsensitiveContains("use about")
        }
        return filtered.isEmpty ? nil : filtered
    }

    private func daysLabel(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == 1 || rounded == -1 {
            return "1 day"
        }
        if rounded == rounded.rounded() {
            let count = Int(rounded)
            return "\(count) days"
        }
        return String(format: "%.1f days", rounded)
    }

    private func rateLabel(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value)) days/month"
        }
        return String(format: "%.1f days/month", value)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func parsedDays(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
}

private struct LeavePCSTimelineCard: View {
    @Binding var pcsDate: Date
    let daysUntilPCS: Int

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                todayColumn

                dateConnector

                pcsDateColumn
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 14)

            timelineSummary
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var todayColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today", systemImage: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)

            Text(compactDate(Date()))
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today, \(compactDate(Date()))")
    }

    private var pcsDateColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("PCS date", systemImage: "suitcase.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)

            DatePicker(
                "PCS date",
                selection: $pcsDate,
                in: today...Date.distantFuture,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("PCS date")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateConnector: some View {
        VStack(spacing: 4) {
            Spacer(minLength: 22)

            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            Spacer(minLength: 0)
        }
        .frame(width: 28)
    }

    private var timelineSummary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "clock.badge.checkmark")
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(countdownTitle)
                    .font(.subheadline.weight(.semibold))

                Text(countdownDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var countdownTitle: String {
        switch daysUntilPCS {
        case 0:
            "PCS is today"
        case 1:
            "1 day until PCS"
        default:
            "\(daysUntilPCS) days until PCS"
        }
    }

    private var countdownDetail: String {
        if daysUntilPCS == 0 {
            return "Report date is \(compactDate(pcsDate))."
        }
        return "Report on \(compactDate(pcsDate))."
    }

    private func compactDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

private struct LeaveSpecialLeaveCard: View {
    @Binding var balanceText: String
    @Binding var hasExpiration: Bool
    @Binding var expiresDate: Date
    var focusedField: FocusState<LeaveInputField?>.Binding

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("0", text: $balanceText)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: .specialLeave)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .onChange(of: balanceText) { _, newValue in
                        balanceText = sanitizedLeaveInput(newValue, maxValue: 60)
                    }
                    .accessibilityLabel("Special leave balance")

                Text("days")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 14)

            Toggle(isOn: $hasExpiration) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Has an expiration date")
                        .font(.subheadline.weight(.medium))

                    Text("Turn on if this leave must be used by a set date.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if hasExpiration {
                Divider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Expires", systemImage: "hourglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)

                    DatePicker(
                        "Expires",
                        selection: $expiresDate,
                        in: Calendar.current.startOfDay(for: Date())...Date.distantFuture,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Special leave expiration date")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sanitizedLeaveInput(_ input: String, maxValue: Double) -> String {
        var filtered = ""
        var hasDecimal = false

        for character in input {
            if character.isNumber {
                filtered.append(character)
            } else if character == "." && !hasDecimal {
                hasDecimal = true
                filtered.append(character)
            }
        }

        if filtered == "." {
            return "0."
        }

        if let value = Double(filtered), value > maxValue {
            if maxValue == maxValue.rounded() {
                return String(Int(maxValue))
            }
            return String(format: "%.1f", maxValue)
        }

        return filtered
    }
}

// MARK: - Components

private struct LeavePlannerSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct LeaveVerdictHeader: View {
    let isPositive: Bool
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(isPositive ? Color.green : Color.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct LeaveComparisonItem {
    enum Emphasis {
        case normal
        case highlight
    }

    let label: String
    let value: Double
    let emphasis: Emphasis
}

private struct LeaveComparisonRow: View {
    let items: [LeaveComparisonItem]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Spacer(minLength: 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedValue(item.value))
                        .font(item.emphasis == .highlight ? .title3.weight(.bold) : .title3.weight(.semibold))
                        .foregroundStyle(item.emphasis == .highlight ? AppTheme.accent : .primary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formattedValue(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }
}

private struct LeaveCoverageBar: View {
    let current: Double
    let projected: Double
    let required: Double

    private var progress: Double {
        guard required > 0 else { return 0 }
        return min(projected / required, 1.25)
    }

    private var meetsNeed: Bool {
        projected + 0.05 >= required
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Projected vs. needed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(meetsNeed ? "Enough" : "Not enough")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(meetsNeed ? Color.green : Color.orange)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))

                    Capsule()
                        .fill(meetsNeed ? Color.green.opacity(0.85) : Color.orange.opacity(0.85))
                        .frame(width: proxy.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 8)
        }
    }
}

private struct LeaveInsightRow: View {
    let systemImage: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LeaveInsightCard: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keep in mind")
                .font(.subheadline.weight(.semibold))

            ForEach(notes, id: \.self) { note in
                LeaveInsightRow(systemImage: "lightbulb", tint: AppTheme.accent, text: note)
            }
        }
        .appCardStyle(padding: 16, background: AppTheme.accent.opacity(0.06))
    }
}

private struct LeavePlannerSubsection<Content: View>: View {
    let title: String
    var caption: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                if let caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
        }
    }
}

private struct LeaveDateRangeCard: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let dayCount: Int?

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                dateColumn(
                    title: "Starts",
                    systemImage: "airplane.departure",
                    date: $startDate,
                    minDate: today
                )

                dateConnector

                dateColumn(
                    title: "Ends",
                    systemImage: "flag.checkered",
                    date: $endDate,
                    minDate: startDate
                )
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)

            if let dayCount, dayCount > 0 {
                Divider()
                    .padding(.horizontal, 14)

                durationSummary(days: dayCount)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var dateConnector: some View {
        VStack(spacing: 4) {
            Spacer(minLength: 22)

            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            Spacer(minLength: 0)
        }
        .frame(width: 28)
    }

    private func dateColumn(
        title: String,
        systemImage: String,
        date: Binding<Date>,
        minDate: Date
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)

            DatePicker(
                title,
                selection: date,
                in: minDate...Date.distantFuture,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func durationSummary(days: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(days) calendar day\(days == 1 ? "" : "s") of leave")
                    .font(.subheadline.weight(.semibold))

                Text(durationDetail(days: days))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private func durationDetail(days: Int) -> String {
        if days == 1 {
            return "Same-day leave counts as one day."
        }
        return "\(compactDate(startDate)) through \(compactDate(endDate)), inclusive."
    }

    private func compactDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

private enum LeaveInputField: Hashable {
    case currentBalance
    case maxBalanceAtPCS
    case specialLeave
    case accrualRate
}

private struct LeaveNumberFieldView: View {
    let label: String
    @Binding var text: String
    let field: LeaveInputField
    var focusedField: FocusState<LeaveInputField?>.Binding
    var showsLabel: Bool = true
    var detail: String?
    let maxValue: Double
    var unitLabel: String = "days"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsLabel {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: field)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .onChange(of: text) { _, newValue in
                        text = sanitizedLeaveInput(newValue, maxValue: maxValue)
                    }

                Text(unitLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func sanitizedLeaveInput(_ input: String, maxValue: Double) -> String {
        var filtered = ""
        var hasDecimal = false

        for character in input {
            if character.isNumber {
                filtered.append(character)
            } else if character == "." && !hasDecimal {
                hasDecimal = true
                filtered.append(character)
            }
        }

        if filtered == "." {
            return "0."
        }

        if let value = Double(filtered), value > maxValue {
            return formattedInput(maxValue)
        }

        return filtered
    }

    private func formattedInput(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    NavigationStack {
        LeavePlannerView()
    }
}
