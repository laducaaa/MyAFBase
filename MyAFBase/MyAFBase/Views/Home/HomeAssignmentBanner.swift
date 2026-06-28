import SwiftUI

struct HomeAssignmentBanner: View {
    let baseID: String
    let baseName: String

    @Environment(AssignmentProfileStore.self) private var assignmentProfileStore

    private var profile: AssignmentProfile {
        assignmentProfileStore.profile(for: baseID)
    }

    var body: some View {
        if let message = bannerMessage {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: bannerIcon)
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(message.title)
                        .font(.subheadline.weight(.semibold))
                    Text(message.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .appCardStyle(padding: 0, background: AppTheme.accent.opacity(0.08))
        }
    }

    private var bannerIcon: String {
        switch profile.phase {
        case .inbound: "airplane.arrival"
        case .stationed: "house.fill"
        case .outbound: "airplane.departure"
        }
    }

    private var bannerMessage: (title: String, subtitle: String)? {
        switch profile.phase {
        case .inbound:
            guard let reportDate = profile.reportDate else { return nil }
            return (
                countdownTitle(subject: "Report", date: reportDate),
                "In processing at \(baseName) · open Assignment for your checklist."
            )

        case .outbound:
            guard let pcsDate = profile.pcsDate else { return nil }
            return (
                countdownTitle(subject: "PCS", date: pcsDate),
                "Out processing from \(baseName) · use Leave Planner to check balances."
            )

        case .stationed:
            if let pcsDate = profile.pcsDate {
                let days = assignmentProfileStore.daysUntilPCS(for: baseID) ?? 0
                if days >= 0, days <= 120 {
                    return (
                        countdownTitle(subject: "PCS", date: pcsDate),
                        "Planning ahead · set phase to Out Processing when out-processing starts."
                    )
                }
            }
            return nil
        }
    }

    private func countdownTitle(subject: String, date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        switch days {
        case ..<0: return "\(subject) date has passed"
        case 0: return "\(subject) is today"
        case 1: return "1 day until \(subject)"
        default: return "\(days) days until \(subject)"
        }
    }
}
