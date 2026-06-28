import Foundation
import SwiftData

@Observable
final class ReadinessTrackerStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func tracker(for baseID: String) -> ReadinessTracker {
        if let existing = fetch(baseID: baseID) {
            return existing
        }

        let tracker = ReadinessTracker(baseID: baseID)
        modelContext.insert(tracker)
        try? modelContext.save()
        return tracker
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
