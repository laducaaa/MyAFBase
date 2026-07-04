import SwiftUI

struct EmergencyCallRow: View {
    let emergency: EmergencyNumber

    var body: some View {
        Button {
            ResourceAction.call(number: emergency.number)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(isUniversalEmergency ? AppTheme.danger : .primary)
                    .frame(width: 44, height: 44)
                    .background(iconBackground, in: Circle())

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
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            .overlay {
                if isUniversalEmergency {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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

    private var iconBackground: Color {
        if isUniversalEmergency {
            return AppTheme.danger.opacity(0.12)
        }
        return Color(.secondarySystemFill)
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
