import WidgetKit
import SwiftUI

struct ReadinessWidgetEntry: TimelineEntry {
    let date: Date
    let baseName: String
    let countdowns: [ReadinessWidgetItemSnapshot]
}

struct ReadinessTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = ReadinessWidgetEntry
    typealias Intent = ReadinessCountdownWidgetIntent

    func placeholder(in context: Context) -> ReadinessWidgetEntry {
        sampleEntry(for: context.family)
    }

    func snapshot(for configuration: ReadinessCountdownWidgetIntent, in context: Context) async -> ReadinessWidgetEntry {
        if context.isPreview {
            return sampleEntry(for: context.family)
        }
        return entry(for: configuration, family: context.family)
    }

    func timeline(
        for configuration: ReadinessCountdownWidgetIntent,
        in context: Context
    ) async -> Timeline<ReadinessWidgetEntry> {
        let entry = entry(for: configuration, family: context.family)
        let nextRefresh = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)

        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func entry(for configuration: ReadinessCountdownWidgetIntent, family: WidgetFamily) -> ReadinessWidgetEntry {
        let snapshot = WidgetDataStore.loadReadiness()
        let selectedKinds = resolvedKinds(from: configuration, family: family)
        let countdowns: [ReadinessWidgetItemSnapshot]

        if let snapshot {
            countdowns = selectedKinds.compactMap { snapshot.item(for: $0) }
        } else {
            countdowns = selectedKinds.map { kind in
                ReadinessWidgetItemSnapshot(
                    kind: kind.rawValue,
                    title: kind.title,
                    systemImage: kind.systemImage,
                    countdownValue: nil,
                    countdownLabel: "Not set",
                    detailLabel: "Open MyAFBase",
                    statusRaw: "notSet"
                )
            }
        }

        return ReadinessWidgetEntry(
            date: .now,
            baseName: snapshot?.activeBaseName ?? "MyAFBase",
            countdowns: countdowns
        )
    }

    private func resolvedKinds(from configuration: ReadinessCountdownWidgetIntent, family: WidgetFamily) -> [ReadinessItemKind] {
        let limit = maxItems(for: family)
        let configured = configuration.items
            .compactMap { ReadinessItemKind(rawValue: $0.id) }

        if !configured.isEmpty {
            return Array(configured.prefix(limit))
        }

        switch family {
        case .systemSmall:
            return [.fitness]
        case .systemMedium:
            return [.fitness, .dental, .eval]
        case .systemLarge:
            return Array(ReadinessItemKind.widgetKinds.prefix(limit))
        default:
            return [.fitness]
        }
    }

    private func maxItems(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: 1
        case .systemMedium: 3
        case .systemLarge: 6
        default: 1
        }
    }

    private func sampleEntry(for family: WidgetFamily) -> ReadinessWidgetEntry {
        let samples: [ReadinessWidgetItemSnapshot] = [
            ReadinessWidgetItemSnapshot(
                kind: ReadinessItemKind.fitness.rawValue,
                title: "PT test",
                systemImage: "figure.run",
                countdownValue: 24,
                countdownLabel: "days",
                detailLabel: "Jul 21, 2026",
                statusRaw: "onTrack"
            ),
            ReadinessWidgetItemSnapshot(
                kind: ReadinessItemKind.dental.rawValue,
                title: "Dental",
                systemImage: "mouth.fill",
                countdownValue: 8,
                countdownLabel: "days",
                detailLabel: "Jul 5, 2026",
                statusRaw: "dueSoon"
            ),
            ReadinessWidgetItemSnapshot(
                kind: ReadinessItemKind.eval.rawValue,
                title: "EPR / OPB",
                systemImage: "doc.text.fill",
                countdownValue: 45,
                countdownLabel: "days",
                detailLabel: "Aug 11, 2026",
                statusRaw: "onTrack"
            )
        ]

        let limit = maxItems(for: family)
        return ReadinessWidgetEntry(
            date: .now,
            baseName: "Eglin AFB",
            countdowns: Array(samples.prefix(limit))
        )
    }
}
