import SwiftUI

struct PTCalculatorView: View {
    @State private var gender: PFRAGender = .male
    @State private var age = 25
    @State private var heightFeet = 5
    @State private var heightInches = 9
    @State private var waistTenths = 320

    @State private var cardioEvent: PFRACardioEvent = .twoMileRun
    @State private var runMinutes = 15
    @State private var runSeconds = 0
    @State private var hamrShuttles = 50

    @State private var strengthEvent: PFRAStrengthEvent = .pushUps
    @State private var strengthReps = 40

    @State private var coreEvent: PFRACoreEvent = .sitUps
    @State private var coreReps = 45
    @State private var plankMinutes = 2
    @State private var plankSeconds = 0

    private var heightTotalInches: Double {
        Double(heightFeet * 12 + heightInches)
    }

    private var waistInches: Double {
        Double(waistTenths) / 10.0
    }

    private var pfraAssessment: PFRAResult? {
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

        return PFRAScoring.evaluate(
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
                if let assessment = pfraAssessment {
                    resultsSection(assessment)
                }

                scoresInputCard
                disclaimerCard
            }
            .padding()
        }
        .appScreenBackground()
        .navigationTitle("PFRA Score Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Results

    private func resultsSection(_ assessment: PFRAResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            verdictCard(assessment)
            componentScoresCard(assessment)
        }
    }

    private func verdictCard(_ assessment: PFRAResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            PFRAPlannerVerdictHeader(
                isPositive: assessment.passed,
                title: verdictTitle(for: assessment),
                subtitle: verdictSubtitle(for: assessment)
            )

            PFRACompositeComparisonRow(
                current: assessment.compositeScore,
                target: PFRAScoring.passComposite,
                targetLabel: "To pass"
            )

            PFRACompositeProgressBar(
                current: assessment.compositeScore,
                target: PFRAScoring.passComposite,
                label: "Pass progress",
                passingLabel: "Passing"
            )

            ForEach(assessment.guidance, id: \.self) { tip in
                PFRAInsightRow(
                    systemImage: assessment.passed ? "checkmark.circle.fill" : "arrow.up.circle.fill",
                    tint: assessment.passed ? .green : .orange,
                    text: tip
                )
            }
        }
        .appCardStyle(padding: 20)
        .animation(.easeInOut(duration: 0.2), value: assessment.compositeScore)
    }

    private func componentScoresCard(_ assessment: PFRAResult) -> some View {
        let failing = assessment.componentScores.filter { !$0.passed }

        return VStack(alignment: .leading, spacing: 14) {
            PFRAPlannerSectionHeader(
                title: failing.isEmpty ? "All components pass" : "Component scores",
                subtitle: failing.isEmpty
                    ? "Every area meets the minimum point requirements."
                    : "\(failing.count) component\(failing.count == 1 ? "" : "s") below the minimum."
            )

            ForEach(Array(assessment.componentScores.enumerated()), id: \.element.id) { index, score in
                PFRACalculatorScoreRow(score: score)

                if index < assessment.componentScores.count - 1 {
                    Divider()
                }
            }
        }
        .appCardStyle(padding: 20)
    }

    // MARK: - Inputs

    private var scoresInputCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            PFRAPlannerSectionHeader(
                title: "Your scores",
                subtitle: "Update these to refresh your estimate."
            )

            VStack(alignment: .leading, spacing: 16) {
                PFRAPlannerSubsection(title: "Profile") {
                    profileInputs
                }

                PFRAPlannerSubsection(title: "Body composition") {
                    bodyInputs
                }

                PFRAPlannerSubsection(title: "Cardio") {
                    cardioInputs
                }

                PFRAPlannerSubsection(title: "Strength") {
                    strengthInputs
                }

                PFRAPlannerSubsection(title: "Core") {
                    coreInputs
                }
            }
        }
        .appCardStyle(padding: 20)
    }

    private var profileInputs: some View {
        VStack(spacing: 12) {
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
    }

    private var bodyInputs: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                PFRACompactStepper(
                    label: "Feet",
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
                    label: "Inches",
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

            if heightTotalInches > 0 {
                Text(whtrCaption)
                    .font(.caption)
                    .foregroundStyle(whtrFails ? Color.orange : Color.secondary)
            }
        }
    }

    private var cardioInputs: some View {
        VStack(spacing: 12) {
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
        }
    }

    private var strengthInputs: some View {
        VStack(spacing: 12) {
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
        }
    }

    private var coreInputs: some View {
        VStack(spacing: 12) {
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
        }
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
        let ratio = waistInches / heightTotalInches
        let formatted = String(format: "WHtR %.2f", ratio)
        return ratio >= 0.60 ? "\(formatted) — fails at 0.60+" : formatted
    }

    private var whtrFails: Bool {
        guard heightTotalInches > 0 else { return false }
        return waistInches / heightTotalInches >= 0.60
    }

    private func clampHeightInches() {
        if heightFeet == 7 {
            heightInches = min(heightInches, 11)
        }
    }
}

// MARK: - Score row

private struct PFRACalculatorScoreRow: View {
    let score: PFRAComponentScore

    private var minimumPoints: Double {
        score.name == "Cardio" ? PFRAScoring.cardioMinimum : PFRAScoring.componentMinimum
    }

    private var progress: Double {
        guard score.maxPoints > 0 else { return 0 }
        return min(score.points / score.maxPoints, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(score.name)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                Text(String(format: "%.1f", score.points))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(score.passed ? Color.primary : Color.orange)

                Text("/ \(Int(score.maxPoints))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(score.detail)
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(score.passed ? Color.green.opacity(0.85) : Color.orange.opacity(0.85))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 6)

            Text(score.passed ? "Meets minimum" : "Need \(formattedMinimum) to pass")
                .font(.caption2.weight(.medium))
                .foregroundStyle(score.passed ? Color.green : .orange)
        }
    }

    private var formattedMinimum: String {
        if score.name == "Cardio" {
            return String(format: "%.0f", minimumPoints)
        }
        return String(format: "%.1f", minimumPoints)
    }
}

#Preview {
    NavigationStack {
        PTCalculatorView()
    }
}
