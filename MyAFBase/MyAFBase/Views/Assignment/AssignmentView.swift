import SwiftUI

enum AssignmentSegment: String, CaseIterable, Identifiable {
    case inbound
    case stationed
    case outbound

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbound: "In Processing"
        case .stationed: "Stationed"
        case .outbound: "Out Processing"
        }
    }
}

struct AssignmentView: View {
    @Environment(AppState.self) private var appState
    @Environment(AssignmentProfileStore.self) private var assignmentProfileStore

    @State private var primaryActionSheet: NewcomerPrimaryAction?

    var body: some View {
        NavigationStack {
            Group {
                if let base = appState.currentBase {
                    assignmentContent(for: base)
                } else if appState.isBaseLoading {
                    BaseLoadingView()
                } else {
                    EmptyStateView.noBaseSelected {
                        appState.shouldShowBasePicker = true
                    }
                }
            }
            .appScreenBackground()
            .navigationTitle("My Assignment")
            .navigationDestination(for: NewcomerSection.self) { section in
                NewcomerSectionDetailView(section: section)
            }
            .sheet(item: $primaryActionSheet) { action in
                LocationDetailSheet(
                    title: action.title,
                    hours: nil,
                    address: action.address,
                    phone: action.phone,
                    url: action.url,
                    description: nil,
                    gateStatus: nil,
                    traffic: nil,
                    onOpenMaps: action.address.map { address in
                        { MapsHelper.open(address: address) }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func assignmentContent(for base: Base) -> some View {
        let segment = assignmentProfileStore.phase(for: base.id)

        ScrollView {
            VStack(spacing: AssignmentMetrics.sectionSpacing) {
                AssignmentPhaseHeader(base: base, segment: segment)

                AssignmentDatesCard(baseID: base.id, segment: segment)

                switch segment {
                case .inbound:
                    inboundContent(for: base)
                case .stationed:
                    stationedContent(for: base)
                case .outbound:
                    outboundContent(for: base)
                }

                if let formatted = base.formattedDataUpdated {
                    Label("Base data updated \(formatted)", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }

    // MARK: - In Processing

    @ViewBuilder
    private func inboundContent(for base: Base) -> some View {
        let newcomers = base.newcomers
        let primaryAction = newcomers.resolvedPrimaryAction(resources: base.resources)

        PCSChecklistCard(baseID: base.id, kind: .inbound)

        if let primaryAction {
            AssignmentSectionHeader(
                title: "Report & Arrive",
                subtitle: "Where to go when you get on base."
            )

            AssignmentActionCard(
                title: primaryAction.title,
                subtitle: primaryAction.address ?? primaryAction.phone,
                systemImage: "mappin.and.ellipse"
            ) {
                primaryActionSheet = primaryAction
            }
        }

        if !newcomers.sections.isEmpty {
            AssignmentSectionHeader(
                title: "In-Processing Guides",
                subtitle: "Required documents, housing, and in-processing steps."
            )

            VStack(spacing: 10) {
                ForEach(newcomers.sections) { section in
                    NavigationLink(value: section) {
                        AssignmentGuideCard(section: section)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        if let moreInfoURL = newcomers.resolvedMoreInfoURL().flatMap({ SafeURL.webURL(from: $0) }) {
            AssignmentLinkCard(
                title: "Official Newcomer Information",
                subtitle: "Base website and installation resources.",
                systemImage: "safari",
                url: moreInfoURL
            )
        }
    }

    // MARK: - Stationed

    @ViewBuilder
    private func stationedContent(for base: Base) -> some View {
        ReadinessTrackerView(baseID: base.id, baseName: base.name)
    }

    // MARK: - Out Processing

    @ViewBuilder
    private func outboundContent(for base: Base) -> some View {
        AssignmentToolLinksCard(links: [.leavePlanner, .pfraGoalPlanner])

        PCSChecklistCard(baseID: base.id, kind: .outbound)

        AssignmentSectionHeader(
            title: "Out-Processing Locations",
            subtitle: "Places you'll likely need to visit before you PCS."
        )

        AssignmentOutboundLocationsCard(locations: OutboundProcessingLocations.common)

        AssignmentNextBaseCard {
            appState.shouldShowBasePicker = true
        }
    }
}
