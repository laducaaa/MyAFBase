import Foundation
import WidgetKit

enum HomeWidgetSync {
    @MainActor
    static func publishWeather(base: Base, weather: Weather?) {
        let snapshot = WeatherWidgetBuilder.snapshot(from: base, weather: weather)
        WidgetDataStore.saveWeather(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.weather)
    }

    @MainActor
    static func publishOpenNow(base: Base, savedItems: [ResolvedSavedItem] = []) {
        let snapshot = OpenNowWidgetBuilder.snapshot(from: base, savedItems: savedItems)
        WidgetDataStore.saveOpenNow(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.openNow)
    }

    @MainActor
    static func publishEmergency(base: Base) {
        let snapshot = EmergencyWidgetBuilder.snapshot(from: base)
        WidgetDataStore.saveEmergency(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.emergency)
    }

    @MainActor
    static func publishPayCalendar(specialPays: [SpecialPayEntry]) {
        let snapshot = PayWidgetBuilder.snapshot(specialPays: specialPays)
        WidgetDataStore.savePay(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.payCalendar)
    }

    @MainActor
    static func publishPayCalendar() {
        publishPayCalendar(specialPays: SpecialPayStore().entries)
    }

    @MainActor
    static func publishWARTracker(baseID: String, store: WARTrackerStore) {
        let weekStart = WARDateMath.startOfWeek(containing: .now)
        guard let weekEnd = WARDateMath.days(from: weekStart, count: 7).last else { return }
        let count = store.entryCount(for: baseID, in: weekStart...WARDateMath.endOfDay(weekEnd))
        let snapshot = WARWidgetSnapshot(
            baseID: baseID,
            entriesThisWeek: count,
            weekRangeLabel: WARDateMath.rangeLabel(from: weekStart, to: weekEnd),
            updatedAt: .now
        )
        WidgetDataStore.saveWARTracker(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.warQuickLog)
    }
}

@MainActor
enum PayWidgetBuilder {
    static func snapshot(
        from reference: Date = .now,
        specialPays: [SpecialPayEntry] = []
    ) -> PayWidgetSnapshot {
        let events = PayCalendar.upcomingEvents(from: reference, specialPays: specialPays)

        guard let next = events.first else {
            return PayWidgetSnapshot(
                nextTitle: "",
                nextDate: reference,
                daysUntil: 0,
                isSpecial: false,
                symbolName: "dollarsign.circle",
                upcoming: [],
                updatedAt: reference
            )
        }

        let upcoming = events.prefix(4).map { event in
            PayWidgetUpcomingItem(
                title: event.title,
                date: event.date,
                daysUntil: PayCalendar.daysUntil(event.date, from: reference),
                isSpecial: event.isSpecial,
                symbolName: event.systemImage
            )
        }

        return PayWidgetSnapshot(
            nextTitle: next.title,
            nextDate: next.date,
            daysUntil: PayCalendar.daysUntil(next.date, from: reference),
            isSpecial: next.isSpecial,
            symbolName: next.systemImage,
            upcoming: Array(upcoming),
            updatedAt: reference
        )
    }
}

@MainActor
enum WeatherWidgetBuilder {
    static func snapshot(from base: Base, weather: Weather?) -> WeatherWidgetSnapshot {
        guard let weather, !weather.isPlaceholder else {
            return WeatherWidgetSnapshot(
                baseID: base.id,
                baseName: base.name,
                location: base.location,
                tempF: nil,
                feelsLikeF: nil,
                conditionName: "Unavailable",
                symbolName: "cloud.fill",
                windMph: nil,
                humidity: nil,
                isAvailable: false,
                updatedAt: .now
            )
        }

        return WeatherWidgetSnapshot(
            baseID: base.id,
            baseName: base.name,
            location: base.location,
            tempF: Int(weather.tempF.rounded()),
            feelsLikeF: weather.feelsLikeDisplayF,
            conditionName: weather.conditionName,
            symbolName: weather.condition.symbolName,
            windMph: Int(weather.windMph.rounded()),
            humidity: weather.humidity,
            isAvailable: true,
            updatedAt: weather.lastUpdated
        )
    }
}

@MainActor
enum OpenNowWidgetBuilder {
    static func snapshot(from base: Base, savedItems: [ResolvedSavedItem], limit: Int = 8) -> OpenNowWidgetSnapshot {
        let entries = OpenNowCatalog.openEntries(for: base, resourceLimit: 5, gateLimit: 3)
        let items = entries.prefix(limit).map { entry in
            OpenNowWidgetItemSnapshot(
                id: entry.id,
                name: entry.name,
                categoryLabel: entry.categoryLabel,
                systemImage: entry.systemImage,
                detail: entry.detail,
                statusLabel: "Open",
                isOpen: true
            )
        }

        let bookmarks = savedItems.compactMap { buildBookmarkItem($0) }

        return OpenNowWidgetSnapshot(
            baseID: base.id,
            baseName: base.name,
            items: Array(items),
            bookmarks: bookmarks,
            updatedAt: .now
        )
    }

    private static func buildBookmarkItem(_ item: ResolvedSavedItem) -> OpenNowWidgetItemSnapshot? {
        if let gate = item.gate {
            let hoursStatus = ResourceHoursStatus.status(for: gate)
            let isOpen = gate.status != .closed && ResourceHoursStatus.isOpenNow(hoursStatus)
            let statusLabel = gateStatusLabel(gate: gate, hoursStatus: hoursStatus)

            return OpenNowWidgetItemSnapshot(
                id: "\(BookmarkItemType.gate.rawValue)-\(gate.id)",
                name: gate.name,
                categoryLabel: "Gate",
                systemImage: "door.left.hand.open",
                detail: hoursDetail(for: gate.hours),
                statusLabel: statusLabel,
                isOpen: isOpen
            )
        }

        if let resource = item.resource {
            let hoursStatus = ResourceHoursStatus.status(for: resource)
            let isOpen = ResourceHoursStatus.isOpenNow(hoursStatus)
            let statusLabel = hoursStatus.map(ResourceHoursStatus.label(for:)) ?? "Hours unavailable"

            return OpenNowWidgetItemSnapshot(
                id: "\(BookmarkItemType.resource.rawValue)-\(resource.id)",
                name: resource.name,
                categoryLabel: resource.category.displayName,
                systemImage: resource.category.systemImage,
                detail: hoursDetail(for: resource.displayHours),
                statusLabel: statusLabel,
                isOpen: isOpen
            )
        }

        if let event = item.event {
            let detail = event.timeRangeText ?? event.date.formatted(date: .abbreviated, time: .omitted)

            return OpenNowWidgetItemSnapshot(
                id: "\(BookmarkItemType.event.rawValue)-\(event.id)",
                name: event.title,
                categoryLabel: event.category?.displayName ?? "Event",
                systemImage: event.category?.systemImage ?? "calendar",
                detail: detail,
                statusLabel: "Event",
                isOpen: true
            )
        }

        return nil
    }

    private static func gateStatusLabel(gate: Gate, hoursStatus: OpenStatus?) -> String {
        if gate.status == .closed { return "Closed" }
        if gate.status == .delayed { return "Delayed" }
        if let hoursStatus { return ResourceHoursStatus.label(for: hoursStatus) }
        return gate.status.displayName
    }

    private static func hoursDetail(for hours: String?) -> String? {
        guard let hours, !hours.isEmpty else { return nil }
        let parsed = HoursParser.parse(hours)
        return parsed.todayHoursText ?? parsed.mealEntries.first.map {
            HoursParser.summaryHours(for: $0.hoursText) ?? $0.hoursText
        }
    }
}

@MainActor
enum EmergencyWidgetBuilder {
    static func snapshot(from base: Base) -> EmergencyWidgetSnapshot {
        EmergencyWidgetSnapshot(
            baseID: base.id,
            baseName: base.name,
            contacts: prioritize(base.emergencyNumbers).map(contactSnapshot(from:)),
            updatedAt: .now
        )
    }

    static func prioritize(_ numbers: [EmergencyNumber]) -> [EmergencyNumber] {
        var result: [EmergencyNumber] = []
        var remaining = numbers

        func take(where matches: (EmergencyNumber) -> Bool) {
            guard let index = remaining.firstIndex(where: matches) else { return }
            result.append(remaining.remove(at: index))
        }

        take { $0.number.filter(\.isNumber) == "911" }
        take { $0.label.localizedCaseInsensitiveContains("security") }
        take {
            $0.label.localizedCaseInsensitiveContains("hospital")
                || $0.label.localizedCaseInsensitiveContains("medical")
        }
        take { $0.label.localizedCaseInsensitiveContains("fire") }

        result.append(contentsOf: remaining)
        return result
    }

    static func contactSnapshot(from number: EmergencyNumber) -> EmergencyContactSnapshot {
        let isUniversalEmergency = number.number.filter(\.isNumber) == "911"
        return EmergencyContactSnapshot(
            id: number.id,
            label: isUniversalEmergency ? "911" : number.label,
            number: number.number,
            systemImage: systemImage(for: number, isUniversalEmergency: isUniversalEmergency),
            isUniversalEmergency: isUniversalEmergency
        )
    }

    private static func systemImage(for number: EmergencyNumber, isUniversalEmergency: Bool) -> String {
        if isUniversalEmergency { return "exclamationmark.triangle.fill" }
        let label = number.label.lowercased()
        if label.contains("medical") || label.contains("hospital") { return "cross.case.fill" }
        if label.contains("fire") { return "flame.fill" }
        if label.contains("security") { return "shield.fill" }
        return "phone.fill"
    }
}
