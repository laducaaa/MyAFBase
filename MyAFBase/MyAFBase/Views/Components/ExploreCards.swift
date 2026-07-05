import SwiftUI

struct ExploreLocationCard<Footer: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let hoursText: String?
    let hoursStatus: OpenStatus?
    let shareText: String
    let locationLabel: String?
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onTap: () -> Void
    let onLocationTap: (() -> Void)?
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IconBadge(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(ExploreMetrics.cardTitleFont)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        if let hoursStatus {
                            OpenClosedBadge(status: hoursStatus)
                        }
                    }

                    Spacer(minLength: 8)

                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(ExploreMetrics.bookmarkIconFont)
                            .foregroundStyle(.primary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share \(title)")

                    BookmarkButton(isBookmarked: isBookmarked, action: onBookmark)
                }

                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let hoursText, !hoursText.isEmpty {
                            CompactResourceHoursView(hours: hoursText)
                        }

                        if let locationLabel, !locationLabel.isEmpty {
                            Button {
                                onLocationTap?()
                            } label: {
                                ExploreRowLabel(
                                    systemImage: "mappin.and.ellipse",
                                    text: locationLabel,
                                    underlined: true,
                                    foreground: .primary
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()

                        footer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .exploreCardStyle()
    }
}

struct ExploreResourceCard: View {
    let resource: Resource
    let baseID: String
    let baseName: String
    @Environment(BookmarkStore.self) private var bookmarkStore
    @State private var showDetail = false

    var body: some View {
        ExploreLocationCard(
            title: resource.name,
            systemImage: resource.category.systemImage,
            tint: AppTheme.accent,
            hoursText: resource.displayHours,
            hoursStatus: ResourceHoursStatus.status(for: resource),
            shareText: LocationShareBuilder.resource(resource, baseName: baseName),
            locationLabel: resource.displayAddress != nil ? "Location" : nil,
            isBookmarked: bookmarkStore.isBookmarked(baseID: baseID, itemID: resource.id, itemType: .resource),
            onBookmark: { bookmarkStore.toggleResource(baseID: baseID, resourceID: resource.id) },
            onTap: { showDetail = true },
            onLocationTap: openMaps
        ) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(ExploreMetrics.footerLabelFont)
                        .foregroundStyle(.secondary)
                    ExploreRowLabel(
                        systemImage: resource.category.systemImage,
                        text: resource.category.displayName,
                        foreground: .primary
                    )
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showDetail) {
            LocationDetailSheet(
                title: resource.name,
                hours: resource.displayHours,
                address: resource.displayAddress,
                phone: resource.displayPhone,
                url: resource.displayURL,
                description: resource.description,
                gateStatus: nil,
                traffic: nil,
                onOpenMaps: openMaps
            )
        }
    }

    private func openMaps() {
        if let address = resource.displayAddress {
            MapsHelper.open(address: address)
        }
    }
}

struct ExploreGateCard: View {
    let gate: Gate
    let baseID: String
    let baseName: String
    @Environment(BookmarkStore.self) private var bookmarkStore
    @State private var showDetail = false

    var body: some View {
        ExploreLocationCard(
            title: gate.name,
            systemImage: "door.left.hand.open",
            tint: gate.status.color,
            hoursText: gate.hours,
            hoursStatus: ResourceHoursStatus.status(for: gate),
            shareText: LocationShareBuilder.gate(gate, baseName: baseName),
            locationLabel: gate.displayAddress != nil ? "Location" : nil,
            isBookmarked: bookmarkStore.isBookmarked(baseID: baseID, itemID: gate.id, itemType: .gate),
            onBookmark: { bookmarkStore.toggleGate(baseID: baseID, gateID: gate.id) },
            onTap: { showDetail = true },
            onLocationTap: { MapsHelper.open(gate: gate) }
        ) {
            HStack(spacing: 20) {
                gateFooterColumn(title: "Status", systemImage: "door.left.hand.open") {
                    StatusPill(gateStatus: gate.status)
                }
                gateFooterColumn(title: "Traffic", systemImage: "cone") {
                    StatusPill(trafficLevel: gate.traffic)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showDetail) {
            LocationDetailSheet(
                title: gate.name,
                hours: gate.hours,
                address: gate.displayAddress,
                phone: nil,
                url: nil,
                description: gate.notes,
                gateStatus: gate.status,
                traffic: gate.traffic,
                onOpenMaps: { MapsHelper.open(gate: gate) }
            )
        }
        .onChange(of: showDetail) { _, isShowing in
            guard isShowing else { return }
            AppIntentDonations.recordGateViewed(
                gateName: gate.name,
                baseID: baseID,
                baseName: baseName
            )
        }
    }

    private func gateFooterColumn<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ExploreMetrics.footerLabelFont)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(ExploreMetrics.footerIconFont)
                    .frame(width: ExploreMetrics.cardRowIconWidth, alignment: .leading)
                content()
            }
        }
    }
}

struct ExploreEventCard: View {
    let event: Event
    let baseID: String
    let baseName: String
    @Environment(BookmarkStore.self) private var bookmarkStore
    @State private var showDetail = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IconBadge(systemImage: event.category?.systemImage ?? "calendar", tint: AppTheme.accent)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(event.title)
                        .font(ExploreMetrics.cardTitleFont)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    ShareLink(item: LocationShareBuilder.event(event, baseName: baseName)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(ExploreMetrics.bookmarkIconFont)
                            .foregroundStyle(.primary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share \(event.title)")
                    BookmarkButton(
                        isBookmarked: bookmarkStore.isBookmarked(baseID: baseID, itemID: event.id, itemType: .event),
                        action: { bookmarkStore.toggleEvent(baseID: baseID, eventID: event.id) }
                    )
                }

                Button {
                    showDetail = true
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        ExploreRowLabel(
                            systemImage: "calendar",
                            text: event.date.formatted(date: .long, time: .omitted)
                        )

                        if let timeRange = event.timeRangeText {
                            ExploreRowLabel(systemImage: "clock", text: timeRange)
                        }

                        if let address = event.displayAddress {
                            Button {
                                MapsHelper.open(address: address)
                            } label: {
                                ExploreRowLabel(
                                    systemImage: "mappin.and.ellipse",
                                    text: address,
                                    underlined: true,
                                    foreground: .primary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .exploreCardStyle()
        .sheet(isPresented: $showDetail) {
            EventDetailSheet(event: event)
        }
    }
}
