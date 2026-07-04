import SwiftUI

struct PFRAGoalPlannerView: View {
    @State private var target: PFRATargetTier = .satisfactory
    @State private var gender: PFRAGender = .male
    @State private var age = 25
    @State private var heightFeet = 5
    @State private var heightInches = 9
    @State private var waistTenths = 320

    @State private var cardioEvent: PFRACardioEvent = .twoMileRun
    @State private var runMinutes = 16
    @State private var runSeconds = 30
    @State private var hamrShuttles = 45

    @State private var strengthEvent: PFRAStrengthEvent = .pushUps
    @State private var strengthReps = 35

    @State private var coreEvent: PFRACoreEvent = .sitUps
    @State private var coreReps = 40
    @State private var plankMinutes = 1
    @State private var plankSeconds = 45

    private var heightTotalInches: Double {
        Double(heightFeet * 12 + heightInches)
    }

    private var waistInches: Double {
        Double(waistTenths) / 10.0
    }

    private var goalPlan: PFRATargetPlan? {
        guard heightTotalInches > 0, waistInches > 0 else { return nil }

        let cardioValue: Double
        switch cardioEvent {
        case .twoMileRun:
            cardioValue = Double(runMinutes * 60 + runSeconds)
        case .hamr:
            cardioValue = Double(hamrShuttles)
        }

        let coreValue: Double
        switch coreEvent {
        case .sitUps, .crossLegReverseCrunch:
            coreValue = Double(coreReps)
        case .forearmPlank:
            coreValue = Double(plankMinutes * 60 + plankSeconds)
        }

        return PFRAGoalPlanner.plan(
            target: target,
            gender: gender,
            age: age,
            heightInches: heightTotalInches,
            waistInches: waistInches,
            cardioEvent: cardioEvent,
            cardioValue: cardioValue,
            strengthEvent: strengthEvent,
            strengthReps: strengthReps,
            coreEvent: coreEvent,
            coreValue: coreValue
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                goalPickerCard

                if let plan = goalPlan {
                    compositeSummaryCard(plan)
                }

                inputSections
                disclaimerCard
            }
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("PFRA Goal Planner")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Goal

    private var goalPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you aiming for?")
                .font(.headline)

            GlassSegmentToggle(
                options: PFRATargetTier.allCases,
                selection: $target,
                label: \.title,
                layout: .equalWidth
            )

            Text(target.subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(padding: 16)
    }

    // MARK: - Composite summary

    private func compositeSummaryCard(_ plan: PFRATargetPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            PFRAPlannerVerdictHeader(
                isPositive: plan.alreadyMet,
                title: verdictTitle(for: plan),
                subtitle: verdictSubtitle(for: plan)
            )

            PFRACompositeComparisonRow(
                current: plan.currentComposite,
                target: plan.targetComposite,
                currentLabel: "Composite",
                targetLabel: plan.target.title
            )

            PFRACompositeProgressBar(
                current: plan.currentComposite,
                target: plan.targetComposite,
                label: "Goal progress",
                passingLabel: "On target"
            )

            if let note = summaryNote(for: plan) {
                PFRAInsightRow(
                    systemImage: plan.alreadyMet ? "checkmark.circle.fill" : "arrow.up.circle.fill",
                    tint: plan.alreadyMet ? AppTheme.success : AppTheme.warning,
                    text: note
                )
            }
        }
        .appCardStyle(padding: 20)
        .animation(.easeInOut(duration: 0.2), value: plan.currentComposite)
    }

    // MARK: - Inputs

    @ViewBuilder
    private var inputSections: some View {
        profileInputCard

        if let plan = goalPlan {
            bodyCompositionCard(component: componentTarget(named: "Body Composition", in: plan))
            cardioCard(component: componentTarget(named: "Cardio", in: plan))
            strengthCard(component: componentTarget(named: "Strength", in: plan))
            coreCard(component: componentTarget(named: "Core", in: plan))
        } else {
            bodyCompositionCard(component: nil)
            cardioCard(component: nil)
            strengthCard(component: nil)
            coreCard(component: nil)
        }
    }

    private var profileInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profile")
                .font(.headline)

            Picker("Gender", selection: $gender) {
                ForEach(PFRAGender.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            PFRAStepperRow(
                label: "Age",
                valueText: "\(age)",
                onDecrement: { age = max(17, age - 1) },
                onIncrement: { age = min(75, age + 1) }
            )
        }
        .appCardStyle(padding: 16)
    }

    private func bodyCompositionCard(component: PFRAComponentTarget?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Body composition")
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    PFRACompactStepper(
                        label: "Ft",
                        valueText: "\(heightFeet)'",
                        onDecrement: {
                            heightFeet = max(4, heightFeet - 1)
                            clampHeightInches()
                        },
                        onIncrement: {
                            heightFeet = min(7, heightFeet + 1)
                            clampHeightInches()
                        }
                    )
                    PFRACompactStepper(
                        label: "In",
                        valueText: "\(heightInches)\"",
                        onDecrement: {
                            heightInches = max(0, heightInches - 1)
                            clampHeightInches()
                        },
                        onIncrement: {
                            heightInches = min(11, heightInches + 1)
                            clampHeightInches()
                        }
                    )
                }

                PFRAStepperRow(
                    label: "Waist",
                    valueText: String(format: "%.1f\"", waistInches),
                    onDecrement: { waistTenths = max(200, waistTenths - 1) },
                    onIncrement: { waistTenths = min(600, waistTenths + 1) }
                )
            }

            if let component {
                PFRAComponentGoalInline(component: component)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func cardioCard(component: PFRAComponentTarget?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cardio")
                .font(.headline)

            Picker("Event", selection: $cardioEvent) {
                ForEach(PFRACardioEvent.allCases) { event in
                    Text(event.title).tag(event)
                }
            }
            .pickerStyle(.segmented)

            switch cardioEvent {
            case .twoMileRun:
                PFRATimeStepper(label: "2-mile time", minutes: $runMinutes, seconds: $runSeconds, minuteRange: 9...30)
            case .hamr:
                PFRAStepperRow(
                    label: "Shuttles",
                    valueText: "\(hamrShuttles)",
                    onDecrement: { hamrShuttles = max(0, hamrShuttles - 1) },
                    onIncrement: { hamrShuttles = min(120, hamrShuttles + 1) }
                )
            }

            if let component {
                PFRAComponentGoalInline(component: component)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func strengthCard(component: PFRAComponentTarget?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Strength")
                .font(.headline)

            Picker("Event", selection: $strengthEvent) {
                ForEach(PFRAStrengthEvent.allCases) { event in
                    Text(event.shortTitle).tag(event)
                }
            }
            .pickerStyle(.segmented)

            PFRAStepperRow(
                label: "Repetitions",
                valueText: "\(strengthReps)",
                onDecrement: { strengthReps = max(0, strengthReps - 1) },
                onIncrement: { strengthReps = min(120, strengthReps + 1) }
            )

            if let component {
                PFRAComponentGoalInline(component: component)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func coreCard(component: PFRAComponentTarget?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Core")
                .font(.headline)

            Picker("Event", selection: $coreEvent) {
                ForEach(PFRACoreEvent.allCases) { event in
                    Text(event.shortTitle).tag(event)
                }
            }
            .pickerStyle(.segmented)

            switch coreEvent {
            case .sitUps, .crossLegReverseCrunch:
                PFRAStepperRow(
                    label: "Repetitions",
                    valueText: "\(coreReps)",
                    onDecrement: { coreReps = max(0, coreReps - 1) },
                    onIncrement: { coreReps = min(120, coreReps + 1) }
                )
            case .forearmPlank:
                PFRATimeStepper(label: "Hold time", minutes: $plankMinutes, seconds: $plankSeconds, minuteRange: 0...5)
            }

            if let component {
                PFRAComponentGoalInline(component: component)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func componentTarget(named name: String, in plan: PFRATargetPlan) -> PFRAComponentTarget? {
        plan.componentTargets.first { $0.name == name }
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Unofficial estimate based on March 2026 PFRA charts. Assumes other component scores stay the same.")
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

    // MARK: - Copy

    private func verdictTitle(for plan: PFRATargetPlan) -> String {
        if plan.alreadyMet {
            return "You hit \(plan.target.title)"
        }

        let gap = plan.targetComposite - plan.currentComposite
        if gap > 0 {
            return String(format: "%.1f points to \(plan.target.title.lowercased())", gap)
        }
        return "Close to \(plan.target.title.lowercased())"
    }

    private func verdictSubtitle(for plan: PFRATargetPlan) -> String {
        if plan.alreadyMet {
            return String(format: "Composite %.1f — above the %.1f target.", plan.currentComposite, plan.targetComposite)
        }

        if let focus = plan.primaryFocus {
            return "Biggest lift: \(focus.name)"
        }

        return String(format: "Composite %.1f of %.1f needed.", plan.currentComposite, plan.targetComposite)
    }

    private func summaryNote(for plan: PFRATargetPlan) -> String? {
        if let critical = criticalNotes(from: plan).first {
            return critical
        }
        return plan.notes.first
    }

    private func criticalNotes(from plan: PFRATargetPlan) -> [String] {
        plan.notes.filter {
            $0.localizedCaseInsensitiveContains("whtr")
                || $0.localizedCaseInsensitiveContains("body composition fails")
        }
    }

    private func clampHeightInches() {
        if heightFeet == 7 {
            heightInches = min(heightInches, 11)
        }
    }
}

#Preview {
    NavigationStack {
        PFRAGoalPlannerView()
    }
}
