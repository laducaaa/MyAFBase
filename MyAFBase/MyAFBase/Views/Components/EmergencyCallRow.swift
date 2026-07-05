import SwiftUI

struct EmergencyCallRow: View {
    let emergency: EmergencyNumber

    var body: some View {
        Button {
            ResourceAction.call(number: emergency.number)
        } label: {
            HStack(spacing: 14) {
                IconBadge(
                    systemImage: iconName,
                    tint: isUniversalEmergency ? AppTheme.danger : AppTheme.accent,
                    style: isUniversalEmergency ? .solid : .tinted
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(emergency.label)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        if isUniversalEmergency {
                            Text("911")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.danger, in: Capsule())
                        }
                    }

                    Text(emergency.number)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }

                Spacer(minLength: 8)

                trailingAccessory
            }
            .appCardStyle()
            .overlay {
                if isUniversalEmergency {
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.danger.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Call \(emergency.label) at \(emergency.number)")
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if isUniversalEmergency {
            HStack(spacing: 4) {
                Image(systemName: "phone.arrow.up.right")
                Text("Call")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.danger, in: Capsule())
        } else {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private var isUniversalEmergency: Bool {
        emergency.number.filter(\.isNumber) == "911"
    }

    private var iconName: String {
        if isUniversalEmergency {
            return "exclamationmark.triangle.fill"
        }
        if emergency.label.localizedCaseInsensitiveContains("medical")
            || emergency.label.localizedCaseInsensitiveContains("hospital") {
            return "cross.case.fill"
        }
        if emergency.label.localizedCaseInsensitiveContains("fire") {
            return "flame.fill"
        }
        if emergency.label.localizedCaseInsensitiveContains("security") {
            return "shield.fill"
        }
        return "phone.fill"
    }
}
