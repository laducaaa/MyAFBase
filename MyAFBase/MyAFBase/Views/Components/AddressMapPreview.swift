import MapKit
import SwiftUI

struct AddressMapPreview: View {
    let title: String
    let address: String
    let onOpenMaps: () -> Void

    @State private var coordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var lookupFailed = false

    var body: some View {
        Button(action: onOpenMaps) {
            ZStack(alignment: .bottomLeading) {
                mapContent
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 4) {
                    Label(address, systemImage: "mappin.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Map preview for \(title)")
        .accessibilityHint("Opens location in Maps")
        .task(id: address) {
            await resolveCoordinate()
        }
    }

    @ViewBuilder
    private var mapContent: some View {
        if let coordinate {
            Map(position: $cameraPosition, interactionModes: []) {
                Marker(title, coordinate: coordinate)
                    .tint(AppTheme.danger)
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
        } else if lookupFailed {
            ZStack {
                Color(.secondarySystemGroupedBackground)
                VStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Map preview unavailable")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ZStack {
                Color(.secondarySystemGroupedBackground)
                ProgressView()
            }
        }
    }

    @MainActor
    private func resolveCoordinate() async {
        coordinate = nil
        lookupFailed = false
        cameraPosition = .automatic

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                lookupFailed = true
                return
            }

            let resolved = item.location.coordinate
            coordinate = resolved
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: resolved,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                )
            )
        } catch {
            lookupFailed = true
        }
    }
}
