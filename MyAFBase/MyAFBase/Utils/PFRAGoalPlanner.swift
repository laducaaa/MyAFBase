import Foundation

enum PFRATargetTier: String, CaseIterable, Identifiable {
    case satisfactory
    case excellent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .satisfactory: "Satisfactory"
        case .excellent: "Excellent"
        }
    }

    var compositeThreshold: Double {
        switch self {
        case .satisfactory: PFRAScoring.passComposite
        case .excellent: 90
        }
    }

    var subtitle: String {
        switch self {
        case .satisfactory: "75.0 composite minimum"
        case .excellent: "90.0 composite"
        }
    }
}

struct PFRAComponentTarget: Identifiable, Equatable {
    let name: String
    let currentPoints: Double
    let requiredPoints: Double
    let currentDetail: String
    let targetDetail: String
    let needsImprovement: Bool

    var id: String { name }

    var pointsGap: Double {
        max(0, requiredPoints - currentPoints)
    }
}

struct PFRATargetPlan: Equatable {
    let target: PFRATargetTier
    let currentComposite: Double
    let targetComposite: Double
    let alreadyMet: Bool
    let componentTargets: [PFRAComponentTarget]
    let notes: [String]

    var primaryFocus: PFRAComponentTarget? {
        componentTargets
            .filter(\.needsImprovement)
            .max(by: { $0.pointsGap < $1.pointsGap })
    }
}

enum PFRAGoalPlanner {
    static func plan(
        target: PFRATargetTier,
        gender: PFRAGender,
        age: Int,
        heightInches: Double,
        waistInches: Double,
        cardioEvent: PFRACardioEvent,
        cardioValue: Double,
        strengthEvent: PFRAStrengthEvent,
        strengthReps: Int,
        coreEvent: PFRACoreEvent,
        coreValue: Double
    ) -> PFRATargetPlan? {
        guard heightInches > 0, waistInches > 0 else { return nil }

        let current = PFRAScoring.evaluate(
            gender: gender,
            age: age,
            heightInches: heightInches,
            waistInches: waistInches,
            cardioEvent: cardioEvent,
            cardioValue: cardioValue,
            strengthEvent: strengthEvent,
            strengthReps: strengthReps,
            coreEvent: coreEvent,
            coreValue: coreValue
        )

        let targetComposite = target.compositeThreshold
        let alreadyMet: Bool
        switch target {
        case .satisfactory:
            alreadyMet = current.passed && current.compositeScore >= targetComposite
        case .excellent:
            alreadyMet = current.passed && current.compositeScore >= targetComposite
        }

        let ageGroup = PFRAgeGroup.from(age: age)
        var notes: [String] = []

        if waistInches / heightInches >= 0.60 {
            notes.append("Body composition fails at WHtR 0.60+. Reduce waist before other targets are reachable.")
        }

        let componentTargets = current.componentScores.map { score in
            buildComponentTarget(
                score: score,
                targetComposite: targetComposite,
                allScores: current.componentScores,
                gender: gender,
                ageGroup: ageGroup,
                heightInches: heightInches,
                waistInches: waistInches,
                cardioEvent: cardioEvent,
                cardioValue: cardioValue,
                strengthEvent: strengthEvent,
                strengthReps: strengthReps,
                coreEvent: coreEvent,
                coreValue: coreValue
            )
        }

        if alreadyMet {
            notes.append("You already meet the \(target.title.lowercased()) threshold with your current inputs.")
        } else if let deficit = componentTargets.filter(\.needsImprovement).max(by: { $0.pointsGap < $1.pointsGap }) {
            notes.append("Biggest gap: \(deficit.name) — need \(String(format: "%.1f", deficit.pointsGap)) more points there if other scores stay the same.")
        }

        return PFRATargetPlan(
            target: target,
            currentComposite: current.compositeScore,
            targetComposite: targetComposite,
            alreadyMet: alreadyMet,
            componentTargets: componentTargets,
            notes: notes
        )
    }

    private static func buildComponentTarget(
        score: PFRAComponentScore,
        targetComposite: Double,
        allScores: [PFRAComponentScore],
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        heightInches: Double,
        waistInches: Double,
        cardioEvent: PFRACardioEvent,
        cardioValue: Double,
        strengthEvent: PFRAStrengthEvent,
        strengthReps: Int,
        coreEvent: PFRACoreEvent,
        coreValue: Double
    ) -> PFRAComponentTarget {
        let minimum = score.name == "Cardio" ? PFRAScoring.cardioMinimum : PFRAScoring.componentMinimum
        let otherPoints = allScores
            .filter { $0.name != score.name }
            .reduce(0) { $0 + $1.points }
        let pointsForComposite = max(0, targetComposite - otherPoints)
        let requiredPoints = min(score.maxPoints, max(minimum, pointsForComposite))

        let targetDetail = performanceTarget(
            componentName: score.name,
            requiredPoints: requiredPoints,
            gender: gender,
            ageGroup: ageGroup,
            heightInches: heightInches,
            waistInches: waistInches,
            cardioEvent: cardioEvent,
            cardioValue: cardioValue,
            strengthEvent: strengthEvent,
            strengthReps: strengthReps,
            coreEvent: coreEvent,
            coreValue: coreValue
        )

        let needsImprovement = !score.passed || score.points < requiredPoints - 0.05

        return PFRAComponentTarget(
            name: score.name,
            currentPoints: score.points,
            requiredPoints: requiredPoints,
            currentDetail: score.detail,
            targetDetail: targetDetail,
            needsImprovement: needsImprovement
        )
    }

    private static func performanceTarget(
        componentName: String,
        requiredPoints: Double,
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        heightInches: Double,
        waistInches: Double,
        cardioEvent: PFRACardioEvent,
        cardioValue: Double,
        strengthEvent: PFRAStrengthEvent,
        strengthReps: Int,
        coreEvent: PFRACoreEvent,
        coreValue: Double
    ) -> String {
        switch componentName {
        case "Cardio":
            guard let value = PFRAScoring.performanceForCardioPoints(
                gender: gender,
                ageGroup: ageGroup,
                event: cardioEvent,
                targetPoints: requiredPoints
            ) else {
                return "Improve cardio performance"
            }
            switch cardioEvent {
            case .twoMileRun:
                return "Run 2-mile in \(PFRAScoring.formatRunTime(value)) or faster (\(String(format: "%.1f", requiredPoints)) pts)"
            case .hamr:
                return "Complete \(Int(value.rounded(.up)))+ HAMR shuttles (\(String(format: "%.1f", requiredPoints)) pts)"
            }

        case "Body Composition":
            guard let waist = PFRAScoring.waistInchesForWHtRPoints(
                heightInches: heightInches,
                targetPoints: requiredPoints
            ) else {
                return "Reduce waist below fail threshold"
            }
            let ratio = waist / heightInches
            return String(format: "Waist %.1f\" or less (WHtR %.2f, %.1f pts)", waist, ratio, requiredPoints)

        case "Strength":
            guard let reps = PFRAScoring.performanceForStrengthPoints(
                gender: gender,
                ageGroup: ageGroup,
                event: strengthEvent,
                targetPoints: requiredPoints
            ) else {
                return "Increase \(strengthEvent.title.lowercased())"
            }
            return "\(Int(reps.rounded(.up)))+ reps on \(strengthEvent.title.lowercased()) (\(String(format: "%.1f", requiredPoints)) pts)"

        case "Core":
            guard let value = PFRAScoring.performanceForCorePoints(
                gender: gender,
                ageGroup: ageGroup,
                event: coreEvent,
                targetPoints: requiredPoints
            ) else {
                return "Improve \(coreEvent.title.lowercased())"
            }
            switch coreEvent {
            case .sitUps, .crossLegReverseCrunch:
                return "\(Int(value.rounded(.up)))+ reps on \(coreEvent.title.lowercased()) (\(String(format: "%.1f", requiredPoints)) pts)"
            case .forearmPlank:
                return "Hold plank \(PFRAScoring.formatPlankTime(value)) or longer (\(String(format: "%.1f", requiredPoints)) pts)"
            }

        default:
            return "Reach \(String(format: "%.1f", requiredPoints)) points"
        }
    }
}
