import SwiftUI

private enum LeavePlannerMode: String, CaseIterable, Identifiable {
    case trips
    case projection
    case pcs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trips: "Planned Trips"
        case .projection: "By Date"
        case .pcs: "PCS Planning"
        }
    }

    var toggleTitle: String {
        switch self {
        case .trips: "Trips"
        case .projection: "By Date"
        case .pcs: "PCS"
        }
    }

    var subtitle: String {
        switch self {
        case .trips: "Will you have enough leave for every trip?"
        case .projection: "How much leave will you have by a target date?"
        case .pcs: "How much to use before you PCS?"
        }
    }
}

struct LeavePlannerView: View {
    @State private var mode: LeavePlannerMode = .trips
    @State private var currentBalance = 30.0
    @State private var maxBalanceAtPCS = LeavePlanner.defaultMaxBalanceAtPCS
    @State private var specialLeaveBalance = 0.0
    @State private var accrualPerMonth = LeavePlanner.defaultAccrualPerMonth
    @State private var trips = LeavePlannerView.defaultTrips
    @State private var projectionDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var pcsDate = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
    @State private var hasSpecialLeaveExpiration = false
    @State private var specialLeaveExpires = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()

    private var multiTripCoverage: LeaveMultiTripCoverageResult? {
        LeavePlanner.evaluateMultipleTrips(
            currentBalance: currentBalance,
            trips: trips,
            accrualPerMonth: accrualPerMonth
        )
    }

    private var balanceProjection: LeaveBalanceProjectionResult? {
        LeavePlanner.projectBalance(
            currentBalance: currentBalance,
            on: projectionDate,
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

    private var daysUntilPCS: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let pcs = calendar.startOfDay(for: pcsDate)
        return max(0, calendar.dateComponents([.day], from: today, to: pcs).day ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                modePicker

                switch mode {
                case .trips:
                    tripsContent
                case .projection:
                    projectionContent
                case .pcs:
                    pcsContent
                }

                disclaimerCard
            }
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("Leave Planner")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Mode

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you planning?")
                .font(.headline)

            GlassSegmentToggle(
                options: LeavePlannerMode.allCases,
                selection: $mode,
                label: \.toggleTitle,
                layout: .equalWidth
            )

            Text(mode.subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(padding: 16)
    }

    // MARK: - Planned trips

    @ViewBuilder
    private var tripsContent: some View {
        if let coverage = multiTripCoverage {
            multiTripSummaryCard(coverage)
        }

        balanceCard
        accrualCard

        ForEach($trips) { $trip in
            tripCard(trip: $trip, evaluation: evaluation(for: trip.id))
        }

        Button {
            trips.append(
                LeavePlannedTrip(
                    label: "",
                    startDate: today,
                    endDate: today
                )
            )
        } label: {
            Label(trips.count == 1 ? "Add another trip" : "Add trip", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accent)
        .padding(.top, -4)
    }

    private func multiTripSummaryCard(_ coverage: LeaveMultiTripCoverageResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LeaveVerdictHeader(
                isPositive: coverage.allCovered,
                title: coverage.allCovered
                    ? "Enough for all \(coverage.trips.count) \(coverage.trips.count == 1 ? "trip" : "trips")"
                    : "Short on \(coverage.firstFailure?.displayName ?? "a trip")",
                subtitle: "\(daysLabel(coverage.totalLeaveDays)) total across your planned leave"
            )

            if coverage.allCovered {
                LeaveHeroComparisonRow(
                    current: coverage.finalBalance,
                    target: coverage.totalLeaveDays,
                    currentLabel: "After all trips",
                    targetLabel: "Total used"
                )

                LeaveInsightRow(
                    systemImage: "checkmark.circle.fill",
                    tint: AppTheme.success,
                    text: coverage.finalBalance > 0.05
                        ? "About \(daysLabel(coverage.finalBalance)) would remain after your last trip."
                        : "Your trips use exactly what you project to have."
                )
            } else if let failure = coverage.firstFailure {
                LeaveHeroComparisonRow(
                    current: failure.balanceAtStart,
                    target: failure.leaveDays,
                    currentLabel: "At \(failure.displayName)",
                    targetLabel: "You need"
                )

                LeaveCoverageBar(
                    projected: failure.balanceAtStart,
                    required: failure.leaveDays,
                    label: "Balance at trip start"
                )

                LeaveInsightRow(
                    systemImage: "exclamationmark.triangle.fill",
                    tint: AppTheme.warning,
                    text: "Short by \(daysLabel(failure.shortfall)) when \(failure.displayName.lowercased()) starts."
                )
            }

            if let overlap = coverage.overlapWarnings.first {
                LeaveInsightRow(
                    systemImage: "calendar.badge.exclamationmark",
                    tint: AppTheme.warning,
                    text: overlap
                )
            }
        }
        .appCardStyle(padding: 20)
        .animation(.easeInOut(duration: 0.2), value: coverage.finalBalance)
    }

    private func tripCard(trip: Binding<LeavePlannedTrip>, evaluation: LeaveTripEvaluation?) -> some View {
        let tripIndex = trips.firstIndex(where: { $0.id == trip.wrappedValue.id })

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                TextField("Name (optional)", text: trip.label)
                    .font(.headline)
                    .textFieldStyle(.plain)

                if trips.count > 1, let tripIndex {
                    Button {
                        trips.remove(at: tripIndex)
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.danger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove trip")
                }
            }

            LeaveDateRow(label: "Starts", date: trip.startDate, minDate: today)
                .onChange(of: trip.wrappedValue.startDate) { _, newStart in
                    if trip.wrappedValue.endDate < newStart {
                        trip.wrappedValue.endDate = newStart
                    }
                }

            LeaveDateRow(label: "Ends", date: trip.endDate, minDate: trip.wrappedValue.startDate)

            if let dayCount = LeavePlanner.leaveDays(from: trip.wrappedValue.startDate, to: trip.wrappedValue.endDate),
               dayCount > 0 {
                LeaveInlineMetric(
                    systemImage: "calendar.badge.clock",
                    title: "\(dayCount) calendar day\(dayCount == 1 ? "" : "s")",
                    detail: "\(shortDate(trip.wrappedValue.startDate)) – \(shortDate(trip.wrappedValue.endDate))"
                )
            }

            if let evaluation {
                LeaveTripEvaluationInline(evaluation: evaluation)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func evaluation(for tripID: UUID) -> LeaveTripEvaluation? {
        multiTripCoverage?.trips.first { $0.id == tripID }
    }

    // MARK: - Balance projection

    @ViewBuilder
    private var projectionContent: some View {
        if let projection = balanceProjection {
            projectionSummaryCard(projection)
        }

        balanceCard
        accrualCard

        VStack(alignment: .leading, spacing: 14) {
            Text("Target date")
                .font(.headline)

            LeaveDateRow(label: "Project to", date: $projectionDate, minDate: today)

            if let projection = balanceProjection, projection.daysUntilTarget > 0 {
                LeaveInlineMetric(
                    systemImage: "clock",
                    title: "\(projection.daysUntilTarget) day\(projection.daysUntilTarget == 1 ? "" : "s") from now",
                    detail: "At \(rateLabel(accrualPerMonth)) with no leave taken."
                )
            }
        }
        .appCardStyle(padding: 16)
    }

    private func projectionSummaryCard(_ projection: LeaveBalanceProjectionResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LeaveVerdictHeader(
                isPositive: projection.daysUntilTarget >= 0,
                title: projectionTitle(for: projection),
                subtitle: "By \(shortDate(projection.targetDate)) at \(rateLabel(accrualPerMonth))"
            )

            LeaveHeroComparisonRow(
                current: projection.projectedBalance,
                target: projection.currentBalance,
                currentLabel: "Projected",
                targetLabel: "Balance now"
            )

            if projection.accruedAmount > 0.05 {
                LeaveInsightRow(
                    systemImage: "plus.circle.fill",
                    tint: AppTheme.accent,
                    text: "You'll accrue about \(daysLabel(projection.accruedAmount)) before that date."
                )
            }

            if projection.hitAccrualCap {
                LeaveInsightRow(
                    systemImage: "exclamationmark.circle.fill",
                    tint: AppTheme.warning,
                    text: "Projection hits the \(Int(LeavePlanner.defaultMaxAccruingBalance))-day accrual cap."
                )
            }

            if projection.daysUntilTarget < 0 {
                LeaveInsightRow(
                    systemImage: "calendar.badge.exclamationmark",
                    tint: AppTheme.warning,
                    text: "Pick a future date to project accrual."
                )
            }
        }
        .appCardStyle(padding: 20)
        .animation(.easeInOut(duration: 0.2), value: projection.projectedBalance)
    }

    private func projectionTitle(for projection: LeaveBalanceProjectionResult) -> String {
        if projection.daysUntilTarget < 0 {
            return "Choose a future date"
        }
        if projection.accruedAmount < 0.05 {
            return "No change expected"
        }
        let delta = projection.projectedBalance - projection.currentBalance
        if delta > 0.05 {
            return String(format: "+%.1f days projected", delta)
        }
        return String(format: "%.1f days projected", projection.projectedBalance)
    }

    private var accrualCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Accrual")
                .font(.headline)

            LeaveDecimalStepperRow(
                label: "Rate",
                value: $accrualPerMonth,
                step: 0.5,
                range: 0...10,
                unit: "days/mo"
            )

            Text("Active duty usually earns 2.5 days per month.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(padding: 16)
    }

    private static var defaultTrips: [LeavePlannedTrip] {
        let today = Calendar.current.startOfDay(for: Date())
        return [LeavePlannedTrip(label: "", startDate: today, endDate: today)]
    }

    // MARK: - PCS

    @ViewBuilder
    private var pcsContent: some View {
        if let plan {
            pcsSummaryCard(plan)
        }

        balanceCard
        pcsDateCard
        planningCapCard
        specialLeaveCard

        if let plan, plan.needsUsagePlan, !plan.milestones.isEmpty {
            pcsMilestonesCard(plan)
        }

        if let plan, let guidance = pcsGuidanceNotes(from: plan.notes) {
            LeaveInsightCard(notes: guidance)
        }
    }

    private func pcsSummaryCard(_ plan: LeavePlanResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LeaveVerdictHeader(
                isPositive: !plan.needsUsagePlan,
                title: plan.needsUsagePlan ? "Plan to use leave before PCS" : "You're within your PCS cap",
                subtitle: "\(plan.daysUntilPCS) days until PCS · balance \(daysLabel(plan.currentBalance))"
            )

            if plan.needsUsagePlan {
                LeaveHeroComparisonRow(
                    current: plan.currentBalance,
                    target: plan.maxBalanceAtPCS,
                    currentLabel: "Balance now",
                    targetLabel: "PCS cap"
                )

                LeaveInsightRow(
                    systemImage: "flame.fill",
                    tint: AppTheme.warning,
                    text: "Use about \(daysLabel(plan.excessLeave)) before PCS — roughly \(daysLabel(plan.daysPerMonthToUse))/month."
                )
            } else {
                LeaveInsightRow(
                    systemImage: "checkmark.circle.fill",
                    tint: AppTheme.success,
                    text: "No excess leave above your \(daysLabel(plan.maxBalanceAtPCS)) planning cap."
                )
            }
        }
        .appCardStyle(padding: 20)
    }

    // MARK: - Shared input cards

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Starting balance")
                .font(.headline)

            LeaveDecimalStepperRow(
                label: "Balance",
                value: $currentBalance,
                step: 0.5,
                range: 0...120,
                unit: "days"
            )
        }
        .appCardStyle(padding: 16)
    }

    private var pcsDateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PCS move")
                .font(.headline)

            LeaveDateRow(label: "Report date", date: $pcsDate, minDate: today)

            LeaveInlineMetric(
                systemImage: "clock.badge.checkmark",
                title: pcsCountdownTitle,
                detail: pcsCountdownDetail
            )
        }
        .appCardStyle(padding: 16)
    }

    private var planningCapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Planning cap")
                .font(.headline)

            LeaveDecimalStepperRow(
                label: "Max at PCS",
                value: $maxBalanceAtPCS,
                step: 1,
                range: 0...120,
                unit: "days"
            )

            Text("Target max balance at PCS — often 60 days. Confirm with your unit CSS.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(padding: 16)
    }

    private var specialLeaveCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Special leave")
                .font(.headline)

            LeaveDecimalStepperRow(
                label: "On the books",
                value: $specialLeaveBalance,
                step: 0.5,
                range: 0...60,
                unit: "days"
            )

            Toggle(isOn: $hasSpecialLeaveExpiration) {
                Text("Has expiration date")
                    .font(.subheadline)
            }

            if hasSpecialLeaveExpiration {
                LeaveDateRow(label: "Expires", date: $specialLeaveExpires, minDate: today)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func pcsMilestonesCard(_ plan: LeavePlanResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested pace")
                .font(.headline)

            Text("Spread usage so you're on track before PCS.")
                .font(.caption)
                .foregroundStyle(.tertiary)

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
        .appCardStyle(padding: 16)
    }

    // MARK: - Shared

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var pcsCountdownTitle: String {
        switch daysUntilPCS {
        case 0: "PCS is today"
        case 1: "1 day until PCS"
        default: "\(daysUntilPCS) days until PCS"
        }
    }

    private var pcsCountdownDetail: String {
        if daysUntilPCS == 0 {
            return "Report date is \(shortDate(pcsDate))."
        }
        return "Report on \(shortDate(pcsDate))."
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Unofficial planning aid only. Rules vary by status and command — confirm balances, caps, and sell-back with your unit CSS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.tertiary)
            }

            Text(LegalCopy.nonAffiliationOneLine)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
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
            return "\(Int(rounded)) days"
        }
        return String(format: "%.1f days", rounded)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func rateLabel(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value)) days/month"
        }
        return String(format: "%.1f days/month", value)
    }
}

// MARK: - Components

private struct LeaveVerdictHeader: View {
    let isPositive: Bool
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(isPositive ? AppTheme.success : AppTheme.warning)

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

private struct LeaveHeroComparisonRow: View {
    let current: Double
    let target: Double
    var currentLabel: String
    var targetLabel: String

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedValue(current))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(targetLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(formattedValue(target))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
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
    let projected: Double
    let required: Double
    var label: String = "Projected vs. needed"

    private var progress: Double {
        guard required > 0 else { return 0 }
        return min(projected / required, 1.0)
    }

    private var meetsNeed: Bool {
        projected + 0.05 >= required
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(meetsNeed ? "Enough" : "Not enough")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(meetsNeed ? AppTheme.success : AppTheme.warning)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(meetsNeed ? AppTheme.success.opacity(0.85) : AppTheme.warning.opacity(0.85))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

private struct LeaveDecimalStepperRow: View {
    let label: String
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                stepButton(systemImage: "minus") {
                    adjustValue(by: -step)
                }
                Text(formattedValue)
                    .font(.body.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 48)
                    .multilineTextAlignment(.center)
                stepButton(systemImage: "plus") {
                    adjustValue(by: step)
                }
            }

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 52, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var formattedValue: String {
        if value == value.rounded() {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    private func adjustValue(by delta: Double) {
        let stepped = ((value + delta) / step).rounded() * step
        value = min(max(range.lowerBound, stepped), range.upperBound)
    }

    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32, height: 32)
                .background(Color(.tertiarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct LeaveDateRow: View {
    let label: String
    @Binding var date: Date
    let minDate: Date

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer(minLength: 8)

            DatePicker(
                label,
                selection: $date,
                in: minDate...Date.distantFuture,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
    }
}

private struct LeaveInlineMetric: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
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

private struct LeaveTripEvaluationInline: View {
    let evaluation: LeaveTripEvaluation

    private var progress: Double {
        guard evaluation.leaveDays > 0 else { return 0 }
        return min(evaluation.balanceAtStart / evaluation.leaveDays, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", evaluation.balanceAtStart))
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundStyle(evaluation.isCovered ? Color.primary : AppTheme.warning)

                Text("/ \(formattedDays(evaluation.leaveDays)) at start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Label {
                    Text(evaluation.isCovered ? "Covered" : "Short")
                        .font(.caption.weight(.semibold))
                } icon: {
                    Image(systemName: evaluation.isCovered ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.caption)
                }
                .foregroundStyle(evaluation.isCovered ? AppTheme.success : AppTheme.warning)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(evaluation.isCovered ? AppTheme.success.opacity(0.85) : AppTheme.warning.opacity(0.85))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 6)

            Text(
                evaluation.isCovered
                    ? "\(formattedDays(evaluation.balanceAfter)) left after this trip"
                    : "Need \(formattedDays(evaluation.shortfall)) more before this trip"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.top, 2)
    }

    private func formattedDays(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == 1 || rounded == -1 {
            return "1 day"
        }
        if rounded == rounded.rounded() {
            return "\(Int(rounded)) days"
        }
        return String(format: "%.1f days", rounded)
    }
}

private struct LeaveInsightCard: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keep in mind")
                .font(.headline)

            ForEach(notes, id: \.self) { note in
                LeaveInsightRow(systemImage: "lightbulb", tint: AppTheme.accent, text: note)
            }
        }
        .appCardStyle(padding: 16, background: AppTheme.accent.opacity(0.06))
    }
}

#Preview {
    NavigationStack {
        LeavePlannerView()
    }
}
