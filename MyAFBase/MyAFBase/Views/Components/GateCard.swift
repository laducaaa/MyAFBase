import SwiftUI

struct GateCard: View {
    let gate: Gate
    let baseID: String
    let baseName: String
    @Environment(BookmarkStore.self) private var bookmarkStore
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(gate.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    ShareLink(item: LocationShareBuilder.gate(gate, baseName: baseName)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share \(gate.name)")
                    BookmarkButton(
                        isBookmarked: bookmarkStore.isBookmarked(baseID: baseID, itemID: gate.id, itemType: .gate)
                    ) {
                        bookmarkStore.toggleGate(baseID: baseID, gateID: gate.id)
                    }
                }

                HStack(spacing: 8) {
                    StatusPill(gateStatus: gate.status)
                    StatusPill(trafficLevel: gate.traffic)
                    if let hoursStatus = ResourceHoursStatus.status(for: gate) {
                        OpenClosedBadge(status: hoursStatus)
                    }
                }

                Label(gate.hours, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let notes = gate.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .exploreCardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens gate details")
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
}
