import Foundation
import MapKit

actor ExploreMapGeocoder {
    static let shared = ExploreMapGeocoder()

    private var cache: [String: ExploreMapCoordinate] = [:]

    func resolve(_ queries: [ExploreMapAddressQuery]) async -> [ExploreMapPin] {
        var pins: [ExploreMapPin] = []

        for query in queries {
            if let cached = cache[query.query] {
                pins.append(pin(from: query, coordinate: cached))
                continue
            }

            guard let coordinate = await geocode(query.query) else { continue }
            cache[query.query] = coordinate
            pins.append(pin(from: query, coordinate: coordinate))
        }

        return pins
    }

    private func geocode(_ query: String) async -> ExploreMapCoordinate? {
        guard let request = MKGeocodingRequest(addressString: query) else { return nil }

        do {
            let mapItems = try await request.mapItems
            guard let coordinate = mapItems.first?.location.coordinate else { return nil }
            return ExploreMapCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return nil
        }
    }

    private func pin(from query: ExploreMapAddressQuery, coordinate: ExploreMapCoordinate) -> ExploreMapPin {
        ExploreMapPin(
            id: query.id,
            title: query.title,
            subtitle: query.subtitle,
            coordinate: coordinate,
            kind: query.kind,
            systemImage: query.systemImage,
            isApproximate: true
        )
    }
}
