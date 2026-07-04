import SwiftUI

struct PFRAPlannerSectionHeader: View {
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

struct PFRAPlannerSubsection<Content: View>: View {
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

struct PFRAPlannerVerdictHeader: View {
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

struct PFRACompositeComparisonRow: View {
    let current: Double
    let target: Double
    var currentLabel: String = "Now"
    var targetLabel: String = "Target"

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f", current))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(targetLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(String(format: "%.1f", target))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PFRAComponentScoreInline: View {
    let score: PFRAComponentScore

    private var minimumPoints: Double {
        score.name == "Cardio" ? PFRAScoring.cardioMinimum : PFRAScoring.componentMinimum
    }

    private var progress: Double {
        guard score.maxPoints > 0 else { return 0 }
        return min(score.points / score.maxPoints, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", score.points))
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundStyle(score.passed ? Color.primary : AppTheme.warning)

                Text("/ \(Int(score.maxPoints)) pts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Label {
                    Text(score.passed ? "Passes" : "Below min")
                        .font(.caption.weight(.semibold))
                } icon: {
                    Image(systemName: score.passed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.caption)
                }
                .foregroundStyle(score.passed ? AppTheme.success : AppTheme.warning)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(score.passed ? AppTheme.success.opacity(0.85) : AppTheme.warning.opacity(0.85))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text(score.detail)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer(minLength: 8)

                if !score.passed {
                    Text("Need \(formattedMinimum)+")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.warning)
                }
            }
        }
        .padding(.top, 2)
        .animation(.easeInOut(duration: 0.2), value: score.points)
    }

    private var formattedMinimum: String {
        if score.name == "Cardio" {
            return String(format: "%.0f", minimumPoints)
        }
        return String(format: "%.1f", minimumPoints)
    }
}

struct PFRAComponentGoalInline: View {
    let component: PFRAComponentTarget

    private var progress: Double {
        guard component.requiredPoints > 0 else { return 0 }
        return min(component.currentPoints / component.requiredPoints, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", component.currentPoints))
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundStyle(component.needsImprovement ? AppTheme.warning : Color.primary)

                Text("/ \(formattedRequired) goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                if component.needsImprovement, component.pointsGap > 0.05 {
                    Label {
                        Text("+\(formattedGap) pts")
                            .font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.warning)
                } else {
                    Label {
                        Text("On track")
                            .font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.success)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(component.needsImprovement ? AppTheme.warning.opacity(0.85) : AppTheme.success.opacity(0.85))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 6)

            Text(component.currentDetail)
                .font(.caption)
                .foregroundStyle(.tertiary)

            if component.needsImprovement {
                Text(actionableTarget(component.targetDetail))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 2)
        .animation(.easeInOut(duration: 0.2), value: component.currentPoints)
    }

    private var formattedRequired: String {
        if component.name == "Cardio" {
            return String(format: "%.0f", component.requiredPoints)
        }
        return String(format: "%.1f", component.requiredPoints)
    }

    private var formattedGap: String {
        if component.name == "Cardio" {
            return String(format: "%.0f", component.pointsGap)
        }
        return String(format: "%.1f", component.pointsGap)
    }

    private func actionableTarget(_ detail: String) -> String {
        if let range = detail.range(of: " (", options: .backwards),
           detail[range.upperBound...].contains("pts") {
            return String(detail[..<range.lowerBound])
        }
        return detail
    }
}

struct PFRACompositeProgressBar: View {
    let current: Double
    let target: Double
    var label: String = "Composite progress"
    var passingLabel: String = "On target"

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    private var meetsTarget: Bool {
        current + 0.05 >= target
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(meetsTarget ? passingLabel : String(format: "%.0f%% there", progress * 100))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(meetsTarget ? AppTheme.success : .secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(meetsTarget ? AppTheme.success.opacity(0.85) : AppTheme.accent.opacity(0.85))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct PFRAInsightRow: View {
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

struct PFRAStepperRow: View {
    let label: String
    let valueText: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                stepButton(systemImage: "minus", action: onDecrement)
                Text(valueText)
                    .font(.body.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 56)
                    .multilineTextAlignment(.center)
                stepButton(systemImage: "plus", action: onIncrement)
            }
        }
        .padding(.vertical, 2)
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

struct PFRACompactStepper: View {
    let label: String
    let valueText: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(.plain)

            Text(valueText)
                .font(.body.weight(.semibold).monospacedDigit())
                .frame(minWidth: 40)

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PFRATimeStepper: View {
    let label: String
    @Binding var minutes: Int
    @Binding var seconds: Int
    let minuteRange: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)

            HStack(spacing: 16) {
                timeUnit(label: "Min", value: $minutes, range: minuteRange)
                Text(":")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.tertiary)
                timeUnit(label: "Sec", value: $seconds, range: 0...59)
            }
        }
    }

    private func timeUnit(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(.plain)

            Text(String(format: "%02d", value.wrappedValue))
                .font(.body.weight(.semibold).monospacedDigit())
                .frame(minWidth: 36)

            Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension PFRAStrengthEvent {
    var shortTitle: String {
        switch self {
        case .pushUps: "Push-Ups"
        case .handReleasePushUps: "HR Push-Ups"
        }
    }
}

extension PFRACoreEvent {
    var shortTitle: String {
        switch self {
        case .sitUps: "Sit-Ups"
        case .crossLegReverseCrunch: "CLRC"
        case .forearmPlank: "Plank"
        }
    }
}
