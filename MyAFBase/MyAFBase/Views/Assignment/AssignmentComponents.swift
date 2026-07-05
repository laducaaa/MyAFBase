import SwiftUI

struct OutboundProcessingLocation: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

enum OutboundProcessingLocations {
    static let common: [OutboundProcessingLocation] = [
        OutboundProcessingLocation(
            id: "mpf",
            title: "Military Personnel Flight (MPF)",
            detail: "Out-process personnel records and DEERS.",
            systemImage: "person.2"
        ),
        OutboundProcessingLocation(
            id: "finance",
            title: "Finance / Comptroller",
            detail: "Final pay, entitlements, and travel vouchers.",
            systemImage: "dollarsign.circle"
        ),
        OutboundProcessingLocation(
            id: "medical",
            title: "Medical & Dental",
            detail: "Clear medical records and any required appointments.",
            systemImage: "heart.text.square"
        ),
        OutboundProcessingLocation(
            id: "housing",
            title: "Housing Office",
            detail: "Move-out inspection and key turn-in.",
            systemImage: "house"
        ),
        OutboundProcessingLocation(
            id: "supply",
            title: "Supply / Equipment Issue",
            detail: "Return issued gear and clear equipment accounts.",
            systemImage: "shippingbox"
        ),
        OutboundProcessingLocation(
            id: "tmo",
            title: "Transportation (TMO)",
            detail: "HHG shipment scheduling and weight tickets.",
            systemImage: "truck.box"
        )
    ]
}

struct AssignmentSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AssignmentAFICard: View {
    let afi: EssentialAFI

    @Environment(\.openURL) private var openURL

    var body: some View {
        if let url = afi.url {
            Button {
                openURL(url)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    IconBadge(systemImage: afi.systemImage, tint: AppTheme.accent, size: 36)

                    Text(afi.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(afi.publication)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                .appCardStyle(padding: AssignmentMetrics.cardPadding)
            }
            .buttonStyle(.plain)
        }
    }
}

struct AssignmentInboundRowLabel: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    var trailingSystemImage: String = "chevron.right"
    var subtitleLineLimit: Int? = 2
    var tint: Color = AppTheme.accent

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(subtitleLineLimit)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: trailingSystemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(padding: AssignmentMetrics.cardPadding)
    }
}

struct AssignmentLinkCard: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            AssignmentInboundRowLabel(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                trailingSystemImage: "arrow.up.right"
            )
        }
    }
}

struct AssignmentActionCard: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AssignmentInboundRowLabel(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage
            )
        }
        .buttonStyle(.plain)
    }
}

struct AssignmentGuideCard: View {
    let section: NewcomerSection

    var body: some View {
        AssignmentInboundRowLabel(
            title: section.title,
            subtitle: section.body,
            systemImage: section.displayIcon
        )
    }
}

struct AssignmentOutboundLocationsCard: View {
    let locations: [OutboundProcessingLocation]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(locations.enumerated()), id: \.element.id) { index, location in
                HStack(spacing: 14) {
                    IconBadge(systemImage: location.systemImage, tint: AppTheme.accent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(location.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Text(location.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)
                }
                .padding(AssignmentMetrics.cardPadding)

                if index < locations.count - 1 {
                    Divider()
                        .padding(.leading, 50)
                }
            }
        }
        .appCardShell()
    }
}

struct AssignmentNextBaseCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Next Assignment", systemImage: "building.2")
                .font(.headline)

            Text("Switch to your gaining installation to load its inbound checklist, reporting info, and newcomer guides.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Label("Change Base", systemImage: "arrow.triangle.2.circlepath")
                    .labelStyle(AppAccentIconLabelStyle())
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .controlSize(.large)
        }
        .appCardStyle(padding: AssignmentMetrics.cardPadding)
    }
}

struct AssignmentTipCard: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(systemImage: systemImage, tint: AppTheme.accent, size: 36)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .appCardStyle(
            padding: AssignmentMetrics.cardPadding,
            background: Color(.secondarySystemGroupedBackground)
        )
    }
}
