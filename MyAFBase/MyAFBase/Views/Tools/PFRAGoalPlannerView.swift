import SwiftUI
import SwiftData

struct PFRAGoalPlannerView: View {
    @Environment(PFRAProfileStore.self) private var profile
    @State private var showSaveSheet = false

    private var pfraAssessment: PFRAResult? {
        guard profile.heightTotalInches > 0, profile.waistInches > 0 else { return nil }

        return PFRAScoring.evaluate(
            gender: profile.gender,
            age: profile.age,
            heightInches: profile.heightTotalInches,
            waistInches: profile.waistInches,
            cardioEvent: profile.cardioEvent,
            cardioValue: profile.cardioValue,
            strengthEvent: profile.strengthEvent,
            strengthReps: profile.strengthReps,
            coreEvent: profile.coreEvent,
            coreValue: profile.coreValue
        )
    }

    private var goalPlan: PFRATargetPlan? {
        guard profile.heightTotalInches > 0, profile.waistInches > 0 else { return nil }

        return PFRAGoalPlanner.plan(
            target: profile.targetTier,
            gender: profile.gender,
            age: profile.age,
            heightInches: profile.heightTotalInches,
            waistInches: profile.waistInches,
            cardioEvent: profile.cardioEvent,
            cardioValue: profile.cardioValue,
            strengthEvent: profile.strengthEvent,
            strengthReps: profile.strengthReps,
            coreEvent: profile.coreEvent,
            coreValue: profile.coreValue
        )
    }

    var body: some View {
        @Bindable var profile = profile

        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                goalPickerCard(profile: profile)

                if let plan = goalPlan {
                    compositeSummaryCard(plan)
                }

                inputSections(profile: profile)

                PFRASaveScoreButton(enabled: pfraAssessment != nil) {
                    showSaveSheet = true
                }

                disclaimerCard
            }
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("PFRA Goal Planner")
        .navigationBarTitleDisplayMode(.inline)
        .pfraCalculatorChrome(
            showSaveSheet: $showSaveSheet,
            assessment: pfraAssessment,
            includeTargetTier: true,
            defaultKind: .goalPlanning
        )
    }

    // MARK: - Goal

    private func goalPickerCard(profile: PFRAProfileStore) -> some View {
        @Bindable var profile = profile

        return VStack(alignment: .leading, spacing: 12) {
            Text("What are you aiming for?")
                .font(.headline)

            GlassSegmentToggle(
                options: PFRATargetTier.allCases,
                selection: $profile.targetTier,
                label: \.title,
                layout: .equalWidth
            )

            Text(profile.targetTier.subtitle)
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
    private func inputSections(profile: PFRAProfileStore) -> some View {
        profileInputCard(profile: profile)

        if let plan = goalPlan {
            bodyCompositionCard(profile: profile, component: componentTarget(named: "Body Composition", in: plan))
            cardioCard(profile: profile, component: componentTarget(named: "Cardio", in: plan))
            strengthCard(profile: profile, component: componentTarget(named: "Strength", in: plan))
            coreCard(profile: profile, component: componentTarget(named: "Core", in: plan))
        } else {
            bodyCompositionCard(profile: profile, component: nil)
            cardioCard(profile: profile, component: nil)
            strengthCard(profile: profile, component: nil)
            coreCard(profile: profile, component: nil)
        }
    }

    private func profileInputCard(profile: PFRAProfileStore) -> some View {
        @Bindable var profile = profile

        return VStack(alignment: .leading, spacing: 14) {
            Text("Profile")
                .font(.headline)

            Picker("Gender", selection: $profile.gender) {
                ForEach(PFRAGender.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            PFRAStepperRow(
                label: "Age",
                valueText: "\(profile.age)",
                onDecrement: { profile.age = max(17, profile.age - 1) },
                onIncrement: { profile.age = min(75, profile.age + 1) }
            )
        }
        .appCardStyle(padding: 16)
    }

    private func bodyCompositionCard(profile: PFRAProfileStore, component: PFRAComponentTarget?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Body composition")
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    PFRACompactStepper(
                        label: "Ft",
                        valueText: "\(profile.heightFeet)'",
                        onDecrement: {
                            profile.heightFeet = max(4, profile.heightFeet - 1)
                            profile.clampHeightInches()
                        },
                        onIncrement: {
                            profile.heightFeet = min(7, profile.heightFeet + 1)
                            profile.clampHeightInches()
                        }
                    )
                    PFRACompactStepper(
                        label: "In",
                        valueText: "\(profile.heightInches)\"",
                        onDecrement: {
                            profile.heightInches = max(0, profile.heightInches - 1)
                            profile.clampHeightInches()
                        },
                        onIncrement: {
                            profile.heightInches = min(11, profile.heightInches + 1)
                            profile.clampHeightInches()
                        }
                    )
                }

                PFRAStepperRow(
                    label: "Waist",
                    valueText: String(format: "%.1f\"", profile.waistInches),
                    onDecrement: { profile.waistTenths = max(200, profile.waistTenths - 1) },
                    onIncrement: { profile.waistTenths = min(600, profile.waistTenths + 1) }
                )
            }

            if let component {
                PFRAComponentGoalInline(component: component)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func cardioCard(profile: PFRAProfileStore, component: PFRAComponentTarget?) -> some View {
        @Bindable var profile = profile

        return VStack(alignment: .leading, spacing: 14) {
            Text("Cardio")
                .font(.headline)

            Picker("Event", selection: $profile.cardioEvent) {
                ForEach(PFRACardioEvent.allCases) { event in
                    Text(event.title).tag(event)
                }
            }
            .pickerStyle(.segmented)

            switch profile.cardioEvent {
            case .twoMileRun:
                PFRATimeStepper(
                    label: "2-mile time",
                    minutes: $profile.runMinutes,
                    seconds: $profile.runSeconds,
                    minuteRange: 9...30
                )
            case .hamr:
                PFRAStepperRow(
                    label: "Shuttles",
                    valueText: "\(profile.hamrShuttles)",
                    onDecrement: { profile.hamrShuttles = max(0, profile.hamrShuttles - 1) },
                    onIncrement: { profile.hamrShuttles = min(120, profile.hamrShuttles + 1) }
                )
            }

            if let component {
                PFRAComponentGoalInline(component: component)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func strengthCard(profile: PFRAProfileStore, component: PFRAComponentTarget?) -> some View {
        @Bindable var profile = profile

        return VStack(alignment: .leading, spacing: 14) {
            Text("Strength")
                .font(.headline)

            Picker("Event", selection: $profile.strengthEvent) {
                ForEach(PFRAStrengthEvent.allCases) { event in
                    Text(event.shortTitle).tag(event)
                }
            }
            .pickerStyle(.segmented)

            PFRAStepperRow(
                label: "Repetitions",
                valueText: "\(profile.strengthReps)",
                onDecrement: { profile.strengthReps = max(0, profile.strengthReps - 1) },
                onIncrement: { profile.strengthReps = min(120, profile.strengthReps + 1) }
            )

            if let component {
                PFRAComponentGoalInline(component: component)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func coreCard(profile: PFRAProfileStore, component: PFRAComponentTarget?) -> some View {
        @Bindable var profile = profile

        return VStack(alignment: .leading, spacing: 14) {
            Text("Core")
                .font(.headline)

            Picker("Event", selection: $profile.coreEvent) {
                ForEach(PFRACoreEvent.allCases) { event in
                    Text(event.shortTitle).tag(event)
                }
            }
            .pickerStyle(.segmented)

            switch profile.coreEvent {
            case .sitUps, .crossLegReverseCrunch:
                PFRAStepperRow(
                    label: "Repetitions",
                    valueText: "\(profile.coreReps)",
                    onDecrement: { profile.coreReps = max(0, profile.coreReps - 1) },
                    onIncrement: { profile.coreReps = min(120, profile.coreReps + 1) }
                )
            case .forearmPlank:
                PFRATimeStepper(
                    label: "Hold time",
                    minutes: $profile.plankMinutes,
                    seconds: $profile.plankSeconds,
                    minuteRange: 0...5
                )
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
}

#Preview {
    NavigationStack {
        PFRAGoalPlannerView()
            .environment(PFRAProfileStore())
            .environment(PFRARecordStore(modelContext: ModelContainerFactory.preview().mainContext))
    }
}
