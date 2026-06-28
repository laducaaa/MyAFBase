import Foundation

enum LocationShareBuilder {
    static func resource(_ resource: Resource, baseName: String) -> String {
        var lines = [resource.name, baseName]

        if let hours = resource.displayHours {
            lines.append("Hours: \(hours)")
        }
        if let address = resource.displayAddress {
            lines.append(address)
        }
        if let phone = resource.displayPhone {
            lines.append("Phone: \(phone)")
        }
        if let url = resource.displayURL {
            lines.append(url)
        }
        if let description = resource.description, !description.isEmpty {
            lines.append(description)
        }

        return lines.joined(separator: "\n")
    }

    static func gate(_ gate: Gate, baseName: String) -> String {
        var lines = [gate.name, baseName, "Hours: \(gate.hours)", "Status: \(gate.status.displayName)"]

        if let address = gate.displayAddress {
            lines.append(address)
        }
        if let notes = gate.notes, !notes.isEmpty {
            lines.append(notes)
        }

        return lines.joined(separator: "\n")
    }

    static func event(_ event: Event, baseName: String) -> String {
        var lines = [
            event.title,
            baseName,
            event.date.formatted(date: .long, time: .omitted),
            event.location
        ]

        if let timeRange = event.timeRangeText {
            lines.append(timeRange)
        }
        if let address = event.displayAddress {
            lines.append(address)
        }
        if !event.description.isEmpty {
            lines.append(event.description)
        }

        return lines.joined(separator: "\n")
    }
}

enum ResourceHoursStatus {
    static func status(for resource: Resource) -> OpenStatus? {
        guard let hours = resource.displayHours else { return nil }
        return HoursParser.parse(hours).status
    }

    static func status(for gate: Gate) -> OpenStatus? {
        guard !gate.hours.isEmpty else { return nil }
        return HoursParser.parse(gate.hours).status
    }

    static func isOpenNow(_ status: OpenStatus?) -> Bool {
        guard let status else { return false }
        return status == .open || status == .alwaysOpen
    }

    static func label(for status: OpenStatus) -> String {
        switch status {
        case .open, .alwaysOpen: "Open"
        case .closed: "Closed"
        }
    }
}
