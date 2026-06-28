import Foundation
import SwiftData

@Observable
final class ChecklistStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func isCompleted(baseID: String, itemID: String, kind: PCSChecklistKind) -> Bool {
        completion(baseID: baseID, itemID: itemID, kind: kind) != nil
    }

    func completedCount(baseID: String, kind: PCSChecklistKind) -> Int {
        let kindValue = kind.rawValue
        let descriptor = FetchDescriptor<ChecklistCompletion>(
            predicate: #Predicate { $0.baseID == baseID && $0.kind == kindValue }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    func toggle(baseID: String, itemID: String, kind: PCSChecklistKind) {
        if let existing = completion(baseID: baseID, itemID: itemID, kind: kind) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(
                ChecklistCompletion(baseID: baseID, itemID: itemID, kind: kind.rawValue)
            )
        }
        try? modelContext.save()
        bumpRevision()
    }

    func clear(baseID: String, kind: PCSChecklistKind) {
        let kindValue = kind.rawValue
        let descriptor = FetchDescriptor<ChecklistCompletion>(
            predicate: #Predicate { $0.baseID == baseID && $0.kind == kindValue }
        )
        guard let completions = try? modelContext.fetch(descriptor) else { return }
        for completion in completions {
            modelContext.delete(completion)
        }
        try? modelContext.save()
        bumpRevision()
    }

    private(set) var revision = 0

    private func bumpRevision() {
        revision += 1
    }

    private func completion(baseID: String, itemID: String, kind: PCSChecklistKind) -> ChecklistCompletion? {
        let kindValue = kind.rawValue
        let descriptor = FetchDescriptor<ChecklistCompletion>(
            predicate: #Predicate {
                $0.baseID == baseID && $0.itemID == itemID && $0.kind == kindValue
            }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
