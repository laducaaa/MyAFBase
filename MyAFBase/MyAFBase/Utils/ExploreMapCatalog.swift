import CoreLocation
import Foundation

enum ExploreMapPinKind: String, Equatable, Sendable {
    case base
    case gate
    case resource
    case event
}

struct ExploreMapCoordinate: Equatable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ExploreMapPin: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let coordinate: ExploreMapCoordinate
    let kind: ExploreMapPinKind
    let systemImage: String
    let isApproximate: Bool
}

struct ExploreMapAddressQuery: Hashable, Sendable {
    let id: String
    let query: String
    let title: String
    let subtitle: String?
    let kind: ExploreMapPinKind
    let systemImage: String
}

enum ExploreMapCatalog {
    static func directPins(
        base: Base,
        gates: [Gate],
        resources: [Resource],
        events: [Event],
        includeBaseCenter: Bool = true
    ) -> [ExploreMapPin] {
        var pins: [ExploreMapPin] = []

        if includeBaseCenter {
            pins.append(
                ExploreMapPin(
                    id: "base-\(base.id)",
                    title: base.name,
                    subtitle: base.location,
                    coordinate: ExploreMapCoordinate(latitude: base.latitude, longitude: base.longitude),
                    kind: .base,
                    systemImage: "building.2.fill",
                    isApproximate: false
                )
            )
        }

        for gate in gates {
            guard let coordinate = gate.mapCoordinate else { continue }
            pins.append(
                ExploreMapPin(
                    id: "gate-\(gate.id)",
                    title: gate.name,
                    subtitle: gate.displayAddress,
                    coordinate: coordinate,
                    kind: .gate,
                    systemImage: "door.left.hand.open",
                    isApproximate: false
                )
            )
        }

        for resource in resources {
            guard let coordinate = resource.mapCoordinate else { continue }
            pins.append(
                ExploreMapPin(
                    id: "resource-\(resource.id)",
                    title: resource.name,
                    subtitle: resource.displayAddress,
                    coordinate: coordinate,
                    kind: .resource,
                    systemImage: resource.category.systemImage,
                    isApproximate: false
                )
            )
        }

        for event in events {
            guard let coordinate = event.mapCoordinate else { continue }
            pins.append(
                ExploreMapPin(
                    id: "event-\(event.id)",
                    title: event.title,
                    subtitle: event.displayAddress,
                    coordinate: coordinate,
                    kind: .event,
                    systemImage: event.category?.systemImage ?? "calendar",
                    isApproximate: false
                )
            )
        }

        return pins
    }

    static func addressQueries(
        base: Base,
        gates: [Gate],
        resources: [Resource],
        events: [Event],
        limit: Int = 10
    ) -> [ExploreMapAddressQuery] {
        var queries: [ExploreMapAddressQuery] = []

        for gate in gates where gate.mapCoordinate == nil {
            guard let query = geocodeQuery(for: gate.displayAddress, base: base) else { continue }
            queries.append(
                ExploreMapAddressQuery(
                    id: "gate-\(gate.id)",
                    query: query,
                    title: gate.name,
                    subtitle: gate.displayAddress,
                    kind: .gate,
                    systemImage: "door.left.hand.open"
                )
            )
        }

        for resource in resources where resource.mapCoordinate == nil {
            guard let query = geocodeQuery(for: resource.displayAddress, base: base) else { continue }
            queries.append(
                ExploreMapAddressQuery(
                    id: "resource-\(resource.id)",
                    query: query,
                    title: resource.name,
                    subtitle: resource.displayAddress,
                    kind: .resource,
                    systemImage: resource.category.systemImage
                )
            )
        }

        for event in events where event.mapCoordinate == nil {
            guard let query = geocodeQuery(for: event.displayAddress, base: base) else { continue }
            queries.append(
                ExploreMapAddressQuery(
                    id: "event-\(event.id)",
                    query: query,
                    title: event.title,
                    subtitle: event.displayAddress,
                    kind: .event,
                    systemImage: event.category?.systemImage ?? "calendar"
                )
            )
        }

        return Array(queries.prefix(limit))
    }

    static func mapRegion(for pins: [ExploreMapPin], fallback: Base) -> (center: ExploreMapCoordinate, spanDelta: Double) {
        let coordinates = pins.map(\.coordinate)
        guard !coordinates.isEmpty else {
            return (
                ExploreMapCoordinate(latitude: fallback.latitude, longitude: fallback.longitude),
                0.08
            )
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLat = latitudes.min() ?? fallback.latitude
        let maxLat = latitudes.max() ?? fallback.latitude
        let minLon = longitudes.min() ?? fallback.longitude
        let maxLon = longitudes.max() ?? fallback.longitude

        let center = ExploreMapCoordinate(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max((maxLat - minLat) * 1.35, 0.02)
        let lonDelta = max((maxLon - minLon) * 1.35, 0.02)
        let spanDelta = max(latDelta, lonDelta, 0.04)

        return (center, spanDelta)
    }

    private static func geocodeQuery(for address: String?, base: Base) -> String? {
        guard let address, !address.isEmpty else { return nil }
        if address.localizedCaseInsensitiveContains(base.location) {
            return address
        }
        return "\(address), \(base.location)"
    }
}

private extension Gate {
    var mapCoordinate: ExploreMapCoordinate? {
        guard let latitude, let longitude else { return nil }
        return ExploreMapCoordinate(latitude: latitude, longitude: longitude)
    }
}

private extension Event {
    var mapCoordinate: ExploreMapCoordinate? {
        nil
    }
}
