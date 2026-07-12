import SwiftUI
import SwiftData

struct PTCalculatorView: View {
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

    var body: some View {
        @Bindable var profile = profile

        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if let assessment = pfraAssessment {
                    compositeSummaryCard(assessment)
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
        .navigationTitle("PFRA Score Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .pfraCalculatorChrome(
            showSaveSheet: $showSaveSheet,
            assessment: pfraAssessment,
            defaultKind: .diagnostic
        )
    }

    // MARK: - Composite summary

    private func compositeSummaryCard(_ assessment: PFRAResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            PFRAPlannerVerdictHeader(
                isPositive: assessment.passed,
                title: verdictTitle(for: assessment),
                subtitle: verdictSubtitle(for: assessment)
            )

            PFRACompositeComparisonRow(
                current: assessment.compositeScore,
                target: PFRAScoring.passComposite,
                currentLabel: "Composite",
                targetLabel: "To pass"
            )

            PFRACompositeProgressBar(
                current: assessment.compositeScore,
                target: PFRAScoring.passComposite,
                label: "Pass progress",
                passingLabel: "Passing"
            )

            if let tip = assessment.guidance.first {
                PFRAInsightRow(
                    systemImage: assessment.passed ? "checkmark.circle.fill" : "arrow.up.circle.fill",
                    tint: assessment.passed ? AppTheme.success : AppTheme.warning,
                    text: tip
                )
            }
        }
        .appCardStyle(padding: 20)
        .animation(.easeInOut(duration: 0.2), value: assessment.compositeScore)
    }

    // MARK: - Inputs

    @ViewBuilder
    private func inputSections(profile: PFRAProfileStore) -> some View {
        profileInputCard(profile: profile)

        if let assessment = pfraAssessment {
            bodyCompositionCard(profile: profile, score: componentScore(named: "Body Composition", in: assessment))
            cardioCard(profile: profile, score: componentScore(named: "Cardio", in: assessment))
            strengthCard(profile: profile, score: componentScore(named: "Strength", in: assessment))
            coreCard(profile: profile, score: componentScore(named: "Core", in: assessment))
        } else {
            bodyCompositionCard(profile: profile, score: nil)
            cardioCard(profile: profile, score: nil)
            strengthCard(profile: profile, score: nil)
            coreCard(profile: profile, score: nil)
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

    private func bodyCompositionCard(profile: PFRAProfileStore, score: PFRAComponentScore?) -> some View {
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

            if let score {
                PFRAComponentScoreInline(score: score)
            } else if profile.heightTotalInches > 0 {
                Text(whtrCaption)
                    .font(.caption)
                    .foregroundStyle(whtrFails ? AppTheme.warning : Color.secondary)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func cardioCard(profile: PFRAProfileStore, score: PFRAComponentScore?) -> some View {
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

            if let score {
                PFRAComponentScoreInline(score: score)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func strengthCard(profile: PFRAProfileStore, score: PFRAComponentScore?) -> some View {
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

            if let score {
                PFRAComponentScoreInline(score: score)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func coreCard(profile: PFRAProfileStore, score: PFRAComponentScore?) -> some View {
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

            if let score {
                PFRAComponentScoreInline(score: score)
            }
        }
        .appCardStyle(padding: 16)
    }

    private func componentScore(named name: String, in assessment: PFRAResult) -> PFRAComponentScore? {
        assessment.componentScores.first { $0.name == name }
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Unofficial estimate based on March 2026 PFRA charts. Pass requires 75.0 composite and minimum points in every component.")
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

            Link(destination: URL(string: "https://www.afpc.af.mil/Career-Management/Fitness-Program/")!) {
                Label("Official AFPC Fitness Program", systemImage: "safari")
                    .font(.caption.weight(.medium))
            }
        }
        .appCardStyle(padding: 14, background: Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Copy

    private func verdictTitle(for assessment: PFRAResult) -> String {
        if assessment.passed {
            return "You pass"
        }

        let gap = PFRAScoring.passComposite - assessment.compositeScore
        if gap > 0 {
            return String(format: "%.1f points to pass", gap)
        }
        return "Below pass standard"
    }

    private func verdictSubtitle(for assessment: PFRAResult) -> String {
        if assessment.passed {
            return "\(assessment.rating) · composite \(String(format: "%.1f", assessment.compositeScore))"
        }

        if let focus = assessment.componentScores.filter({ !$0.passed }).max(by: { $0.points < $1.points }) {
            return "\(assessment.rating) · focus on \(focus.name)"
        }

        return "\(assessment.rating) · composite \(String(format: "%.1f", assessment.compositeScore))"
    }

    private var whtrCaption: String {
        let ratio = profile.waistInches / profile.heightTotalInches
        let formatted = String(format: "WHtR %.2f", ratio)
        return ratio >= 0.60 ? "\(formatted) — fails at 0.60+" : formatted
    }

    private var whtrFails: Bool {
        guard profile.heightTotalInches > 0 else { return false }
        return profile.waistInches / profile.heightTotalInches >= 0.60
    }
}

#Preview {
    NavigationStack {
        PTCalculatorView()
            .environment(PFRAProfileStore())
            .environment(PFRARecordStore(modelContext: ModelContainerFactory.preview().mainContext))
    }
}
