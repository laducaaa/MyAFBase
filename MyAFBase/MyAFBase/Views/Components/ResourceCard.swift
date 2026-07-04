import SwiftUI

struct ResourceCard: View {
    let resource: Resource
    let baseID: String
    let baseName: String
    @Environment(BookmarkStore.self) private var bookmarkStore
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: resource.category.systemImage)
                            .foregroundStyle(AppTheme.accent)
                        Text(resource.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    if let status = ResourceHoursStatus.status(for: resource) {
                        OpenClosedBadge(status: status)
                    }
                }

                Spacer()

                ShareLink(item: LocationShareBuilder.resource(resource, baseName: baseName)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share \(resource.name)")

                BookmarkButton(
                    isBookmarked: bookmarkStore.isBookmarked(baseID: baseID, itemID: resource.id, itemType: .resource)
                ) {
                    let wasBookmarked = bookmarkStore.isBookmarked(
                        baseID: baseID,
                        itemID: resource.id,
                        itemType: .resource
                    )
                    bookmarkStore.toggleResource(baseID: baseID, resourceID: resource.id)
                    if !wasBookmarked {
                        AppIntentDonations.recordResourceBookmarked(
                            resourceName: resource.name,
                            baseID: baseID,
                            baseName: baseName
                        )
                    }
                }
            }

            Text(resource.category.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let description = resource.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let phone = resource.displayPhone {
                    Button("Call") {
                        ResourceAction.call(number: phone)
                    }
                    .font(.subheadline.weight(.medium))
                    .appButtonTextForeground()
                } else if let url = resource.displayURL, let linkURL = SafeURL.webURL(from: url) {
                    Link("Open", destination: linkURL)
                        .font(.subheadline.weight(.medium))
                        .appButtonTextForeground()
                } else if let hours = resource.displayHours {
                    Text(HoursParser.cardDisplay(for: hours, maxLines: 1).lines.first?.value ?? hours)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button("Details") {
                    showDetail = true
                }
                .font(.caption.weight(.medium))
                .appButtonTextForeground()
            }
        }
        .padding(16)
        .exploreCardStyle()
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
                onOpenMaps: {
                    if let address = resource.displayAddress {
                        MapsHelper.open(address: address)
                    }
                }
            )
        }
        .accessibilityElement(children: .contain)
    }
}
