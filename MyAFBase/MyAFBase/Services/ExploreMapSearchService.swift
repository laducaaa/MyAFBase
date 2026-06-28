import MapKit

@MainActor
struct ExploreMapSearchMarker: Identifiable, Hashable {
    let id: String
    let mapItem: MKMapItem

    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        let coordinate = mapItem.exploreCoordinate
        let name = mapItem.name ?? "place"
        self.id = "\(name)-\(coordinate.latitude)-\(coordinate.longitude)"
    }

    static func == (lhs: ExploreMapSearchMarker, rhs: ExploreMapSearchMarker) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
enum ExploreMapSearchService {
    static let defaultSpanDelta: Double = 0.12

    static func baseRegion(for base: Base) -> MKCoordinateRegion {
        baseRegion(for: base, spanDelta: defaultSpanDelta)
    }

    static func baseRegion(for base: Base, spanDelta: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: base.latitude, longitude: base.longitude),
            span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
        )
    }

    static func search(query: String, base: Base) async -> [ExploreMapSearchMarker] {
        await search(query: query, base: base, spanDelta: defaultSpanDelta)
    }

    static func search(
        query: String,
        base: Base,
        spanDelta: Double
    ) async -> [ExploreMapSearchMarker] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(trimmed) \(base.name)"
        request.region = baseRegion(for: base, spanDelta: spanDelta)
        request.resultTypes = [.pointOfInterest, .address]

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.map(ExploreMapSearchMarker.init(mapItem:))
        } catch {
            return []
        }
    }

    static func region(
        for markers: [ExploreMapSearchMarker],
        fallback base: Base,
        paddingFactor: Double = 1.35
    ) -> MKCoordinateRegion {
        guard !markers.isEmpty else {
            return baseRegion(for: base)
        }

        let coordinates = markers.map(\.mapItem.exploreCoordinate)
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        let center = CLLocationCoordinate2D(
            latitude: (latitudes.min()! + latitudes.max()!) / 2,
            longitude: (longitudes.min()! + longitudes.max()!) / 2
        )

        let latDelta = max((latitudes.max()! - latitudes.min()!) * paddingFactor, 0.02)
        let lonDelta = max((longitudes.max()! - longitudes.min()!) * paddingFactor, 0.02)
        let span = max(latDelta, lonDelta, 0.04)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }
}

private extension MKMapItem {
    var exploreCoordinate: CLLocationCoordinate2D {
        location.coordinate
    }
}
