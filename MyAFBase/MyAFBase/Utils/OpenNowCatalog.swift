import Foundation

struct OpenNowEntry: Identifiable, Equatable {
    enum Kind: Equatable {
        case resource(ResourceCategory)
        case gate
    }

    let id: String
    let name: String
    let kind: Kind
    let detail: String?

    var categoryLabel: String {
        switch kind {
        case .resource(let category):
            return category.displayName
        case .gate:
            return "Gate"
        }
    }

    var systemImage: String {
        switch kind {
        case .resource(let category):
            return category.systemImage
        case .gate:
            return "door.left.hand.open"
        }
    }
}

enum OpenNowCatalog {
    static let featuredResourceCategories: [ResourceCategory] = [.dining, .fitness, .medical]

    static func openEntries(for base: Base, resourceLimit: Int = 5, gateLimit: Int = 3) -> [OpenNowEntry] {
        var entries: [OpenNowEntry] = []

        for resource in openResources(in: base, categories: featuredResourceCategories, limit: resourceLimit) {
            entries.append(
                OpenNowEntry(
                    id: "resource-\(resource.id)",
                    name: resource.name,
                    kind: .resource(resource.category),
                    detail: todayHoursSummary(for: resource.displayHours)
                )
            )
        }

        for gate in openGates(in: base, limit: gateLimit) {
            entries.append(
                OpenNowEntry(
                    id: "gate-\(gate.id)",
                    name: gate.name,
                    kind: .gate,
                    detail: todayHoursSummary(for: gate.hours)
                )
            )
        }

        return entries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func openResources(
        in base: Base,
        categories: [ResourceCategory] = featuredResourceCategories,
        limit: Int? = nil
    ) -> [Resource] {
        let matches = base.resources.filter { resource in
            categories.contains(resource.category)
                && ResourceHoursStatus.isOpenNow(ResourceHoursStatus.status(for: resource))
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let limit {
            return Array(matches.prefix(limit))
        }
        return matches
    }

    static func openGates(in base: Base, limit: Int? = nil) -> [Gate] {
        let matches = base.gates.filter { gate in
            ResourceHoursStatus.isOpenNow(ResourceHoursStatus.status(for: gate))
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let limit {
            return Array(matches.prefix(limit))
        }
        return matches
    }

    private static func todayHoursSummary(for hours: String?) -> String? {
        guard let hours, !hours.isEmpty else { return nil }
        let parsed = HoursParser.parse(hours)
        return parsed.todayHoursText ?? parsed.mealEntries.first.map {
            HoursParser.summaryHours(for: $0.hoursText) ?? $0.hoursText
        }
    }
}
