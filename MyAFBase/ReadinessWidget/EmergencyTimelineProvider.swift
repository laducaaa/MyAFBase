import WidgetKit

struct EmergencyWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: EmergencyWidgetSnapshot
    let selectedContact: EmergencyContactSnapshot?
}

struct EmergencyTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = EmergencyWidgetEntry
    typealias Intent = EmergencyWidgetIntent

    func placeholder(in context: Context) -> EmergencyWidgetEntry {
        sampleEntry(selectedContact: EmergencyWidgetSnapshot.sample.contacts.first)
    }

    func snapshot(for configuration: EmergencyWidgetIntent, in context: Context) async -> EmergencyWidgetEntry {
        if context.isPreview {
            return sampleEntry(selectedContact: EmergencyWidgetSnapshot.sample.contacts.first)
        }
        return entry(for: configuration, family: context.family)
    }

    func timeline(for configuration: EmergencyWidgetIntent, in context: Context) async -> Timeline<EmergencyWidgetEntry> {
        let entry = entry(for: configuration, family: context.family)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 12, to: .now) ?? .now.addingTimeInterval(43_200)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func entry(for configuration: EmergencyWidgetIntent, family: WidgetFamily) -> EmergencyWidgetEntry {
        let snapshot = WidgetDataStore.loadEmergency() ?? .placeholder
        let selected = resolvedContact(from: configuration, snapshot: snapshot, family: family)
        return EmergencyWidgetEntry(date: .now, snapshot: snapshot, selectedContact: selected)
    }

    private func resolvedContact(
        from configuration: EmergencyWidgetIntent,
        snapshot: EmergencyWidgetSnapshot,
        family: WidgetFamily
    ) -> EmergencyContactSnapshot? {
        guard family == .systemSmall else { return nil }

        if let contactID = configuration.contact?.id,
           let match = snapshot.contact(id: contactID) {
            return match
        }

        return snapshot.contacts.first
    }

    private func sampleEntry(selectedContact: EmergencyContactSnapshot?) -> EmergencyWidgetEntry {
        EmergencyWidgetEntry(date: .now, snapshot: .sample, selectedContact: selectedContact)
    }
}

extension EmergencyWidgetSnapshot {
    static let sample = EmergencyWidgetSnapshot(
        baseID: "eglin",
        baseName: "Eglin AFB",
        contacts: [
            EmergencyContactSnapshot(
                id: "em-911",
                label: "911",
                number: "911",
                systemImage: "exclamationmark.triangle.fill",
                isUniversalEmergency: true
            ),
            EmergencyContactSnapshot(
                id: "em-sf",
                label: "Security Forces",
                number: "850-882-2502",
                systemImage: "shield.fill",
                isUniversalEmergency: false
            ),
            EmergencyContactSnapshot(
                id: "em-hospital",
                label: "Eglin Hospital",
                number: "850-883-8600",
                systemImage: "cross.case.fill",
                isUniversalEmergency: false
            )
        ],
        updatedAt: .now
    )

    static let placeholder = EmergencyWidgetSnapshot(
        baseID: "",
        baseName: "MyAFBase",
        contacts: [],
        updatedAt: .now
    )
}
