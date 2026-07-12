import MapKit
import SwiftUI

/// Full-screen Apple Maps experience using native POIs only (no duplicate JSON markers).
struct ExploreNativeMapView: View {
    let base: Base
    let searchText: String
    var isActive: Bool = true

    @State private var cameraPosition: MapCameraPosition
    @State private var mapSelection: MapSelection<MKMapItem>?
    @State private var searchMarkers: [ExploreMapSearchMarker] = []
    @State private var isSearching = false
    @State private var locationService = ExploreMapLocationService()
    @State private var didRequestLocation = false

    init(base: Base, searchText: String, isActive: Bool = true) {
        self.base = base
        self.searchText = searchText
        self.isActive = isActive

        _cameraPosition = State(
            initialValue: .region(ExploreMapSearchService.baseRegion(for: base))
        )
    }

    var body: some View {
        Map(
            position: $cameraPosition,
            selection: $mapSelection
        ) {
            if locationService.isAuthorized {
                UserAnnotation()
            }

            ForEach(searchMarkers) { marker in
                Marker(item: marker.mapItem)
                    .tag(MapSelection(marker.mapItem))
            }
            .mapItemDetailSelectionAccessory(.automatic)
        }
        // Flat standard style — realistic elevation was a major cost on mode switch.
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .all))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapFeatureSelectionAccessory(.automatic)
        .mapFeatureSelectionDisabled { feature in
            feature.kind != .pointOfInterest
        }
        .onChange(of: isActive, initial: true) { _, active in
            guard active, !didRequestLocation else { return }
            didRequestLocation = true
            locationService.requestAccessIfNeeded()
        }
        .task(id: "\(isActive)-\(searchText)") {
            guard isActive else { return }
            await refreshSearchResults()
        }
        .overlay(alignment: .topLeading) {
            if isActive {
                mapChrome
            }
        }
    }

    private var mapChrome: some View {
        HStack(spacing: 8) {
            if isSearching {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching…")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
            } else if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\(searchMarkers.count) results")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Button {
                mapSelection = nil
                searchMarkers = []
                withAnimation {
                    cameraPosition = .region(ExploreMapSearchService.baseRegion(for: base))
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset map to \(base.name)")
        }
        .padding(.leading, 12)
        .padding(.top, 8)
    }

    @MainActor
    private func refreshSearchResults() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            searchMarkers = []
            mapSelection = nil
            return
        }

        isSearching = true
        defer { isSearching = false }

        let results = await ExploreMapSearchService.search(query: trimmed, base: base)
        searchMarkers = results
        mapSelection = nil

        guard !results.isEmpty else { return }

        withAnimation {
            cameraPosition = .region(
                ExploreMapSearchService.region(for: results, fallback: base)
            )
        }
    }
}

// Legacy name used by ExploreView.
struct ExploreMapContainerView: View {
    let base: Base
    let searchText: String
    var isActive: Bool = true

    var body: some View {
        ExploreNativeMapView(base: base, searchText: searchText, isActive: isActive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
