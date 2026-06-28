import SwiftUI

struct HomeOpenNowSection: View {
    let base: Base
    let onExploreOpenNow: (ExploreCategory?) -> Void

    private let displayLimit = 4

    private var entries: [OpenNowEntry] {
        OpenNowCatalog.openEntries(for: base)
    }

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Open now",
                    actionTitle: "Explore",
                    action: { onExploreOpenNow(nil) }
                )

                Text("Dining, fitness, medical, and gates open right now at \(base.name).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(entries.prefix(displayLimit)) { entry in
                        openNowRow(entry)
                    }
                }

                if entries.count > displayLimit {
                    Button("See all open locations") {
                        onExploreOpenNow(nil)
                    }
                    .font(.caption.weight(.medium))
                    .appButtonTextForeground()
                }
            }
        }
    }

    private func openNowRow(_ entry: OpenNowEntry) -> some View {
        Button {
            onExploreOpenNow(exploreCategory(for: entry))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: entry.systemImage)
                    .font(.body)
                    .foregroundStyle(AppTheme.buttonIcon)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text(entry.categoryLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let detail = entry.detail {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 8)

                OpenClosedBadge(status: .open)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func exploreCategory(for entry: OpenNowEntry) -> ExploreCategory? {
        switch entry.kind {
        case .gate:
            return .gates
        case .resource(let category):
            return ExploreCategory.allCases.first { $0.resourceCategory == category }
        }
    }
}
