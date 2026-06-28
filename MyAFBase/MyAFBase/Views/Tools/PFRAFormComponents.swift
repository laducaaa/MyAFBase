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

struct PFRACompositeComparisonRow: View {
    let current: Double
    let target: Double
    var currentLabel: String = "Now"
    var targetLabel: String = "Target"

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            scoreColumn(label: currentLabel, value: current, emphasis: false)
            Spacer(minLength: 8)
            scoreColumn(label: targetLabel, value: target, emphasis: true)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func scoreColumn(label: String, value: Double, emphasis: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", value))
                .font(emphasis ? .title.weight(.bold) : .title2.weight(.semibold))
                .foregroundStyle(emphasis ? AppTheme.accent : .primary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .foregroundStyle(meetsTarget ? Color.green : .secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(meetsTarget ? Color.green.opacity(0.85) : AppTheme.accent.opacity(0.85))
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
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            HStack(spacing: 0) {
                stepButton(systemImage: "minus", action: onDecrement)
                Text(valueText)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 72)
                    .multilineTextAlignment(.center)
                stepButton(systemImage: "plus", action: onIncrement)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
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
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 0) {
                Button(action: onDecrement) {
                    Image(systemName: "minus").frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                Text(valueText)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .frame(maxWidth: .infinity)
                Button(action: onIncrement) {
                    Image(systemName: "plus").frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                timeUnit(label: "Min", value: $minutes, range: minuteRange)
                Text(":").font(.title2.weight(.bold)).foregroundStyle(.secondary)
                timeUnit(label: "Sec", value: $seconds, range: 0...59)
            }
        }
    }

    private func timeUnit(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 8) {
            Text(label).font(.caption2).foregroundStyle(.tertiary)
            HStack(spacing: 0) {
                Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                    Image(systemName: "minus").frame(width: 36, height: 40)
                }
                .buttonStyle(.plain)
                Text(String(format: "%02d", value.wrappedValue))
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 52)
                Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                    Image(systemName: "plus").frame(width: 36, height: 40)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
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
