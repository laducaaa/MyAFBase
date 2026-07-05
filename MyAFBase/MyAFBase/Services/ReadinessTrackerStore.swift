import Foundation
import SwiftData

@Observable
final class ReadinessTrackerStore {
    private let modelContext: ModelContext
    private var cachedTrackers: [String: ReadinessTracker] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Memoized per base ID. `ReadinessTracker` is a SwiftData class, so
    /// mutations made through the cached reference (via `save`) are already
    /// visible everywhere without re-fetching — this just avoids repeating
    /// the fetch (and get-or-create insert+save) on every call, which
    /// otherwise runs 2-3x per Home/Assignment render.
    func tracker(for baseID: String) -> ReadinessTracker {
        if let cached = cachedTrackers[baseID] {
            return cached
        }

        let resolved: ReadinessTracker
        if let existing = fetch(baseID: baseID) {
            resolved = existing
        } else {
            let created = ReadinessTracker(baseID: baseID)
            modelContext.insert(created)
            try? modelContext.save()
            resolved = created
        }

        cachedTrackers[baseID] = resolved
        return resolved
    }

    func save(_ tracker: ReadinessTracker, baseName: String? = nil) {
        tracker.updatedAt = Date()
        try? modelContext.save()

        if let baseName {
            Task { @MainActor in
                ReadinessWidgetSync.publish(tracker: tracker, baseName: baseName)
            }
        }
    }

    func allTrackers() -> [ReadinessTracker] {
        (try? modelContext.fetch(FetchDescriptor<ReadinessTracker>())) ?? []
    }

    private func fetch(baseID: String) -> ReadinessTracker? {
        let id = baseID
        let descriptor = FetchDescriptor<ReadinessTracker>(
            predicate: #Predicate { $0.baseID == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
