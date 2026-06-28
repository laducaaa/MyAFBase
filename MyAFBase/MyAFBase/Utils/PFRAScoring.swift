import Foundation

enum PFRAGender: String, CaseIterable, Identifiable, Codable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        }
    }
}

enum PFRAgeGroup: Int, CaseIterable, Identifiable {
    case under25 = 0
    case age25_29 = 1
    case age30_34 = 2
    case age35_39 = 3
    case age40_44 = 4
    case age45_49 = 5
    case age50_54 = 6
    case age55_59 = 7
    case sixtyPlus = 8

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .under25: "Under 25"
        case .age25_29: "25–29"
        case .age30_34: "30–34"
        case .age35_39: "35–39"
        case .age40_44: "40–44"
        case .age45_49: "45–49"
        case .age50_54: "50–54"
        case .age55_59: "55–59"
        case .sixtyPlus: "60+"
        }
    }

    static func from(age: Int) -> PFRAgeGroup {
        switch age {
        case ..<25: return .under25
        case 25..<30: return .age25_29
        case 30..<35: return .age30_34
        case 35..<40: return .age35_39
        case 40..<45: return .age40_44
        case 45..<50: return .age45_49
        case 50..<55: return .age50_54
        case 55..<60: return .age55_59
        default: return .sixtyPlus
        }
    }
}

enum PFRACardioEvent: String, CaseIterable, Identifiable {
    case twoMileRun
    case hamr

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twoMileRun: "2-Mile Run"
        case .hamr: "20m HAMR"
        }
    }
}

enum PFRAStrengthEvent: String, CaseIterable, Identifiable {
    case pushUps
    case handReleasePushUps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pushUps: "Push-Ups (1 min)"
        case .handReleasePushUps: "Hand-Release Push-Ups (2 min)"
        }
    }
}

enum PFRACoreEvent: String, CaseIterable, Identifiable {
    case sitUps
    case crossLegReverseCrunch
    case forearmPlank

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sitUps: "Sit-Ups (1 min)"
        case .crossLegReverseCrunch: "Cross-Leg Reverse Crunch (2 min)"
        case .forearmPlank: "Forearm Plank"
        }
    }
}

struct PFRAComponentScore: Equatable, Identifiable {
    let name: String
    let points: Double
    let maxPoints: Double
    let passed: Bool
    let detail: String

    var id: String { name }
}

struct PFRAResult: Equatable {
    let compositeScore: Double
    let passed: Bool
    let rating: String
    let componentScores: [PFRAComponentScore]
    let guidance: [String]
}

enum PFRAScoring {
    static let passComposite = 75.0
    static let componentMinimum = 2.5
    static let cardioMinimum = 35.0

    static func evaluate(
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
    ) -> PFRAResult {
        let ageGroup = PFRAgeGroup.from(age: age)

        let bodyScore = scoreWHtR(waist: waistInches, height: heightInches)
        let cardioScore = scoreCardio(
            gender: gender,
            ageGroup: ageGroup,
            event: cardioEvent,
            value: cardioValue
        )
        let strengthScore = scoreStrength(
            gender: gender,
            ageGroup: ageGroup,
            event: strengthEvent,
            reps: strengthReps
        )
        let coreScore = scoreCore(
            gender: gender,
            ageGroup: ageGroup,
            event: coreEvent,
            value: coreValue
        )

        let componentScores = [
            PFRAComponentScore(
                name: "Cardio",
                points: cardioScore.points,
                maxPoints: 50,
                passed: cardioScore.passed,
                detail: cardioScore.detail
            ),
            PFRAComponentScore(
                name: "Body Composition",
                points: bodyScore.points,
                maxPoints: 20,
                passed: bodyScore.passed,
                detail: bodyScore.detail
            ),
            PFRAComponentScore(
                name: "Strength",
                points: strengthScore.points,
                maxPoints: 15,
                passed: strengthScore.passed,
                detail: strengthScore.detail
            ),
            PFRAComponentScore(
                name: "Core",
                points: coreScore.points,
                maxPoints: 15,
                passed: coreScore.passed,
                detail: coreScore.detail
            )
        ]

        let composite = componentScores.reduce(0) { $0 + $1.points }
        let allComponentsPassed = componentScores.allSatisfy(\.passed)
        let passed = composite >= passComposite && allComponentsPassed

        let rating: String
        if !allComponentsPassed || composite < passComposite {
            rating = "Unsatisfactory"
        } else if composite >= 90 {
            rating = "Excellent"
        } else {
            rating = "Satisfactory"
        }

        let guidance = buildGuidance(
            componentScores: componentScores,
            composite: composite,
            gender: gender,
            ageGroup: ageGroup,
            cardioEvent: cardioEvent,
            strengthEvent: strengthEvent,
            coreEvent: coreEvent
        )

        return PFRAResult(
            compositeScore: composite,
            passed: passed,
            rating: rating,
            componentScores: componentScores,
            guidance: guidance
        )
    }

    // MARK: - WHtR

    private static func scoreWHtR(waist: Double, height: Double) -> (points: Double, passed: Bool, detail: String) {
        guard height > 0, waist > 0 else {
            return (0, false, "Enter height and waist")
        }

        let ratio = waist / height
        let formatted = String(format: "%.2f", ratio)

        if ratio >= 0.60 {
            return (0, false, "WHtR \(formatted) — component fail")
        }

        let breakpoints: [(Double, Double)] = [
            (0.49, 20),
            (0.55, 12.5),
            (0.59, 2.5)
        ]

        if ratio <= 0.49 {
            return (20, true, "WHtR \(formatted)")
        }

        var points = 2.5
        for index in 0..<(breakpoints.count - 1) {
            let upper = breakpoints[index]
            let lower = breakpoints[index + 1]
            if ratio > upper.0 && ratio <= lower.0 {
                let progress = (lower.0 - ratio) / (lower.0 - upper.0)
                points = lower.1 + progress * (upper.1 - lower.1)
                break
            }
        }

        let passed = points >= componentMinimum
        return (points, passed, "WHtR \(formatted)")
    }

    // MARK: - Cardio

    private static func scoreCardio(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACardioEvent,
        value: Double
    ) -> (points: Double, passed: Bool, detail: String) {
        switch event {
        case .twoMileRun:
            let best = interpolated(young: twoMileBest50(gender: gender), old: twoMileBest50Old(gender: gender), ageGroup: ageGroup)
            let minimum = interpolated(young: twoMileMin35(gender: gender), old: twoMileMin35Old(gender: gender), ageGroup: ageGroup)
            let points = scoreLowerIsBetter(value: value, best: best, minimum: minimum, maxPoints: 50, minPoints: cardioMinimum)
            let passed = points >= cardioMinimum
            let detail = "2-mile: \(formatRunTime(value))"
            return (points, passed, detail)

        case .hamr:
            let minShuttles = interpolated(young: hamrMin35(gender: gender), old: hamrMin35Old(gender: gender), ageGroup: ageGroup)
            let maxShuttles = interpolated(young: hamrMax50(gender: gender), old: hamrMax50Old(gender: gender), ageGroup: ageGroup)
            let points = scoreHigherIsBetter(
                value: value,
                minimum: minShuttles,
                maximum: maxShuttles,
                maxPoints: 50,
                minPoints: cardioMinimum
            )
            let passed = points >= cardioMinimum
            return (points, passed, "HAMR: \(Int(value)) shuttles")
        }
    }

    // MARK: - Strength

    private static func scoreStrength(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRAStrengthEvent,
        reps: Int
    ) -> (points: Double, passed: Bool, detail: String) {
        let value = Double(reps)
        let minimum: Double
        let maximum: Double

        switch (gender, event) {
        case (.male, .pushUps):
            minimum = interpolated(young: 30, old: 12, ageGroup: ageGroup)
            maximum = interpolated(young: 67, old: 38, ageGroup: ageGroup)
        case (.female, .pushUps):
            minimum = interpolated(young: 15, old: 3, ageGroup: ageGroup)
            maximum = interpolated(young: 50, old: 28, ageGroup: ageGroup)
        case (.male, .handReleasePushUps):
            minimum = interpolated(young: 27, old: 11, ageGroup: ageGroup)
            maximum = interpolated(young: 52, old: 36, ageGroup: ageGroup)
        case (.female, .handReleasePushUps):
            minimum = interpolated(young: 17, old: 1, ageGroup: ageGroup)
            maximum = interpolated(young: 42, old: 26, ageGroup: ageGroup)
        }

        let points = scoreHigherIsBetter(
            value: value,
            minimum: minimum,
            maximum: maximum,
            maxPoints: 15,
            minPoints: componentMinimum
        )
        return (points, points >= componentMinimum, "\(reps) reps")
    }

    // MARK: - Core

    private static func scoreCore(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACoreEvent,
        value: Double
    ) -> (points: Double, passed: Bool, detail: String) {
        switch event {
        case .sitUps, .crossLegReverseCrunch:
            let minimum: Double
            let maximum: Double

            switch (gender, event) {
            case (.male, .sitUps):
                minimum = interpolated(young: 33, old: 17, ageGroup: ageGroup)
                maximum = interpolated(young: 58, old: 42, ageGroup: ageGroup)
            case (.female, .sitUps):
                minimum = interpolated(young: 29, old: 6, ageGroup: ageGroup)
                maximum = interpolated(young: 58, old: 31, ageGroup: ageGroup)
            case (.male, .crossLegReverseCrunch):
                minimum = interpolated(young: 35, old: 19, ageGroup: ageGroup)
                maximum = interpolated(young: 60, old: 44, ageGroup: ageGroup)
            case (.female, .crossLegReverseCrunch):
                minimum = interpolated(young: 33, old: 17, ageGroup: ageGroup)
                maximum = interpolated(young: 58, old: 42, ageGroup: ageGroup)
            default:
                minimum = 0
                maximum = 1
            }

            let points = scoreHigherIsBetter(
                value: value,
                minimum: minimum,
                maximum: maximum,
                maxPoints: 15,
                minPoints: componentMinimum
            )
            return (points, points >= componentMinimum, "\(Int(value)) reps")

        case .forearmPlank:
            let minimum = interpolated(
                young: gender == .male ? 95 : 90,
                old: gender == .male ? 55 : 50,
                ageGroup: ageGroup
            )
            let maximum = interpolated(
                young: gender == .male ? 220 : 215,
                old: gender == .male ? 180 : 175,
                ageGroup: ageGroup
            )
            let points = scoreHigherIsBetter(
                value: value,
                minimum: minimum,
                maximum: maximum,
                maxPoints: 15,
                minPoints: componentMinimum
            )
            return (points, points >= componentMinimum, formatPlankTime(value))
        }
    }

    // MARK: - Guidance

    private static func buildGuidance(
        componentScores: [PFRAComponentScore],
        composite: Double,
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        cardioEvent: PFRACardioEvent,
        strengthEvent: PFRAStrengthEvent,
        coreEvent: PFRACoreEvent
    ) -> [String] {
        var tips: [String] = []

        if composite < passComposite {
            let deficit = passComposite - composite
            tips.append("You need \(String(format: "%.1f", deficit)) more composite points to reach 75.")
        }

        for component in componentScores where !component.passed {
            switch component.name {
            case "Cardio":
                tips.append(cardioPassTip(gender: gender, ageGroup: ageGroup, event: cardioEvent))
            case "Body Composition":
                tips.append("Reduce waist-to-height ratio below 0.59 (2.5 pts minimum). At 0.60+ the component fails.")
            case "Strength":
                tips.append(strengthPassTip(gender: gender, ageGroup: ageGroup, event: strengthEvent))
            case "Core":
                tips.append(corePassTip(gender: gender, ageGroup: ageGroup, event: coreEvent))
            default:
                break
            }
        }

        if tips.isEmpty {
            tips.append("You meet current estimated pass thresholds. Keep training for margin above 75.")
        }

        return tips
    }

    private static func cardioPassTip(gender: PFRAGender, ageGroup: PFRAgeGroup, event: PFRACardioEvent) -> String {
        switch event {
        case .twoMileRun:
            let minimum = interpolated(young: twoMileMin35(gender: gender), old: twoMileMin35Old(gender: gender), ageGroup: ageGroup)
            return "Run the 2-mile in \(formatRunTime(minimum)) or faster for at least 35 cardio points."
        case .hamr:
            let minShuttles = Int(interpolated(young: hamrMin35(gender: gender), old: hamrMin35Old(gender: gender), ageGroup: ageGroup).rounded())
            return "Complete at least \(minShuttles) HAMR shuttles for 35 cardio points."
        }
    }

    private static func strengthPassTip(gender: PFRAGender, ageGroup: PFRAgeGroup, event: PFRAStrengthEvent) -> String {
        let minimum: Int
        switch (gender, event) {
        case (.male, .pushUps):
            minimum = Int(interpolated(young: 30, old: 12, ageGroup: ageGroup).rounded())
        case (.female, .pushUps):
            minimum = Int(interpolated(young: 15, old: 3, ageGroup: ageGroup).rounded())
        case (.male, .handReleasePushUps):
            minimum = Int(interpolated(young: 27, old: 11, ageGroup: ageGroup).rounded())
        case (.female, .handReleasePushUps):
            minimum = Int(interpolated(young: 17, old: 1, ageGroup: ageGroup).rounded())
        }
        return "Hit at least \(minimum) \(event.title.lowercased()) for 2.5 strength points."
    }

    private static func corePassTip(gender: PFRAGender, ageGroup: PFRAgeGroup, event: PFRACoreEvent) -> String {
        switch event {
        case .forearmPlank:
            let minimum = interpolated(young: gender == .male ? 95 : 90, old: gender == .male ? 55 : 50, ageGroup: ageGroup)
            return "Hold forearm plank for at least \(formatPlankTime(minimum)) for 2.5 core points."
        case .sitUps, .crossLegReverseCrunch:
            let minimum: Int
            switch (gender, event) {
            case (.male, .sitUps):
                minimum = Int(interpolated(young: 33, old: 17, ageGroup: ageGroup).rounded())
            case (.female, .sitUps):
                minimum = Int(interpolated(young: 29, old: 6, ageGroup: ageGroup).rounded())
            case (.male, .crossLegReverseCrunch):
                minimum = Int(interpolated(young: 35, old: 19, ageGroup: ageGroup).rounded())
            case (.female, .crossLegReverseCrunch):
                minimum = Int(interpolated(young: 33, old: 17, ageGroup: ageGroup).rounded())
            default:
                minimum = 0
            }
            return "Hit at least \(minimum) \(event.title.lowercased()) for 2.5 core points."
        }
    }

    // MARK: - Threshold tables (March 2026 PFRA charts, Air Force)

    private static func twoMileBest50(gender: PFRAGender) -> Double {
        gender == .male ? 13 * 60 + 25 : 15 * 60 + 30
    }

    private static func twoMileBest50Old(gender: PFRAGender) -> Double {
        gender == .male ? 16 * 60 + 58 : 18 * 60 + 20
    }

    private static func twoMileMin35(gender: PFRAGender) -> Double {
        gender == .male ? 19 * 60 + 45 : 25 * 60 + 23
    }

    private static func twoMileMin35Old(gender: PFRAGender) -> Double {
        gender == .male ? 24 * 60 : 29 * 60 + 40
    }

    private static func hamrMin35(gender: PFRAGender) -> Double {
        gender == .male ? 42 : 21
    }

    private static func hamrMin35Old(gender: PFRAGender) -> Double {
        gender == .male ? 26 : 11
    }

    private static func hamrMax50(gender: PFRAGender) -> Double {
        gender == .male ? 87 : 58
    }

    private static func hamrMax50Old(gender: PFRAGender) -> Double {
        gender == .male ? 65 : 42
    }

    // MARK: - Math helpers

    private static func interpolated(young: Double, old: Double, ageGroup: PFRAgeGroup) -> Double {
        let progress = Double(ageGroup.rawValue) / Double(PFRAgeGroup.sixtyPlus.rawValue)
        return young + (old - young) * progress
    }

    private static func scoreHigherIsBetter(
        value: Double,
        minimum: Double,
        maximum: Double,
        maxPoints: Double,
        minPoints: Double
    ) -> Double {
        guard value >= minimum else { return 0 }
        guard maximum > minimum else { return value >= minimum ? minPoints : 0 }
        if value >= maximum { return maxPoints }
        return minPoints + ((value - minimum) / (maximum - minimum)) * (maxPoints - minPoints)
    }

    private static func scoreLowerIsBetter(
        value: Double,
        best: Double,
        minimum: Double,
        maxPoints: Double,
        minPoints: Double
    ) -> Double {
        guard value <= minimum else { return 0 }
        guard minimum > best else { return value <= best ? maxPoints : minPoints }
        if value <= best { return maxPoints }
        return maxPoints - ((value - best) / (minimum - best)) * (maxPoints - minPoints)
    }

    static func formatRunTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    static func formatPlankTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }

    static func parseRunTime(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }

        if let value = Double(trimmed) {
            return value
        }

        let parts = trimmed.split(separator: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            return nil
        }
        return minutes * 60 + seconds
    }

    static func parsePlankTime(_ text: String) -> Double? {
        if let seconds = parseRunTime(text) {
            return seconds
        }
        let trimmed = text.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.hasSuffix("s"), let value = Double(trimmed.dropLast()) {
            return value
        }
        return nil
    }

    // MARK: - Goal planning (reverse lookup)

    static func cardioPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACardioEvent,
        value: Double
    ) -> Double {
        scoreCardio(gender: gender, ageGroup: ageGroup, event: event, value: value).points
    }

    static func strengthPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRAStrengthEvent,
        reps: Int
    ) -> Double {
        scoreStrength(gender: gender, ageGroup: ageGroup, event: event, reps: reps).points
    }

    static func corePoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACoreEvent,
        value: Double
    ) -> Double {
        scoreCore(gender: gender, ageGroup: ageGroup, event: event, value: value).points
    }

    static func bodyPoints(heightInches: Double, waistInches: Double) -> Double {
        scoreWHtR(waist: waistInches, height: heightInches).points
    }

    static func performanceForCardioPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACardioEvent,
        targetPoints: Double
    ) -> Double? {
        switch event {
        case .twoMileRun:
            let best = interpolated(
                young: twoMileBest50(gender: gender),
                old: twoMileBest50Old(gender: gender),
                ageGroup: ageGroup
            )
            let minimum = interpolated(
                young: twoMileMin35(gender: gender),
                old: twoMileMin35Old(gender: gender),
                ageGroup: ageGroup
            )
            guard cardioPoints(gender: gender, ageGroup: ageGroup, event: event, value: best) >= targetPoints else {
                return nil
            }

            var low = Int(best.rounded())
            var high = Int(minimum.rounded())
            while low < high {
                let mid = (low + high + 1) / 2
                if cardioPoints(gender: gender, ageGroup: ageGroup, event: event, value: Double(mid)) >= targetPoints {
                    low = mid
                } else {
                    high = mid - 1
                }
            }
            return Double(low)

        case .hamr:
            var low = 0
            var high = 120
            while low < high {
                let mid = (low + high) / 2
                if cardioPoints(gender: gender, ageGroup: ageGroup, event: event, value: Double(mid)) >= targetPoints {
                    high = mid
                } else {
                    low = mid + 1
                }
            }
            guard cardioPoints(gender: gender, ageGroup: ageGroup, event: event, value: Double(low)) >= targetPoints else {
                return nil
            }
            return Double(low)
        }
    }

    static func waistInchesForWHtRPoints(heightInches: Double, targetPoints: Double) -> Double? {
        guard heightInches > 0 else { return nil }

        var lowTenths = 1
        var highTenths = Int((heightInches * 0.59 * 10).rounded(.down))
        guard highTenths > lowTenths else { return nil }

        while lowTenths < highTenths {
            let mid = (lowTenths + highTenths) / 2
            let waist = Double(mid) / 10.0
            if bodyPoints(heightInches: heightInches, waistInches: waist) >= targetPoints {
                highTenths = mid
            } else {
                lowTenths = mid + 1
            }
        }

        let waist = Double(lowTenths) / 10.0
        guard bodyPoints(heightInches: heightInches, waistInches: waist) >= targetPoints else {
            return nil
        }
        return waist
    }

    static func performanceForStrengthPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRAStrengthEvent,
        targetPoints: Double
    ) -> Double? {
        var low = 0
        var high = 120
        while low < high {
            let mid = (low + high) / 2
            if strengthPoints(gender: gender, ageGroup: ageGroup, event: event, reps: mid) >= targetPoints {
                high = mid
            } else {
                low = mid + 1
            }
        }
        guard strengthPoints(gender: gender, ageGroup: ageGroup, event: event, reps: low) >= targetPoints else {
            return nil
        }
        return Double(low)
    }

    static func performanceForCorePoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACoreEvent,
        targetPoints: Double
    ) -> Double? {
        switch event {
        case .sitUps, .crossLegReverseCrunch:
            var low = 0
            var high = 120
            while low < high {
                let mid = (low + high) / 2
                if corePoints(gender: gender, ageGroup: ageGroup, event: event, value: Double(mid)) >= targetPoints {
                    high = mid
                } else {
                    low = mid + 1
                }
            }
            guard corePoints(gender: gender, ageGroup: ageGroup, event: event, value: Double(low)) >= targetPoints else {
                return nil
            }
            return Double(low)

        case .forearmPlank:
            var low = 0
            var high = 300
            while low < high {
                let mid = (low + high) / 2
                if corePoints(gender: gender, ageGroup: ageGroup, event: event, value: Double(mid)) >= targetPoints {
                    high = mid
                } else {
                    low = mid + 1
                }
            }
            guard corePoints(gender: gender, ageGroup: ageGroup, event: event, value: Double(low)) >= targetPoints else {
                return nil
            }
            return Double(low)
        }
    }
}
