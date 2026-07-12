import Foundation
import SwiftData

@Observable
@MainActor
final class PFRARecordStore {
    private let modelContext: ModelContext
    private(set) var changeToken = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func saveRecord(
        from profile: PFRAProfileStore,
        result: PFRAResult,
        kind: PFRARecordKind,
        testedAt: Date = Date(),
        note: String? = nil,
        includeTargetTier: Bool = false
    ) -> PFRARecord {
        let record = PFRARecord(
            testedAt: testedAt,
            note: Self.nilIfBlank(note),
            kind: kind,
            targetTier: includeTargetTier ? profile.targetTier : nil,
            gender: profile.gender,
            age: profile.age,
            heightInches: profile.heightTotalInches,
            waistInches: profile.waistInches,
            cardioEvent: profile.cardioEvent,
            cardioValue: profile.cardioValue,
            strengthEvent: profile.strengthEvent,
            strengthReps: profile.strengthReps,
            coreEvent: profile.coreEvent,
            coreValue: profile.coreValue,
            result: result
        )
        modelContext.insert(record)
        save()
        return record
    }

    func delete(_ record: PFRARecord) {
        modelContext.delete(record)
        save()
    }

    func deleteAll() {
        for record in allRecords() {
            modelContext.delete(record)
        }
        save()
    }

    func allRecords() -> [PFRARecord] {
        _ = changeToken
        let descriptor = FetchDescriptor<PFRARecord>(
            sortBy: [
                SortDescriptor(\.testedAt, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Oldest → newest for trend charts.
    func recordsChronological() -> [PFRARecord] {
        allRecords().reversed()
    }

    func record(id: UUID) -> PFRARecord? {
        allRecords().first { $0.id == id }
    }

    var trends: PFRATrendsSummary {
        PFRATrendsSummary(records: allRecords())
    }

    private func save() {
        try? modelContext.save()
        changeToken += 1
    }

    private static func nilIfBlank(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct PFRATrendsSummary {
    struct ScorePoint: Equatable {
        let date: Date
        let score: Double
        let passed: Bool
    }

    let recordCount: Int
    let latestScore: Double?
    let bestScore: Double?
    let averageScore: Double?
    let previousScore: Double?
    let deltaFromPrevious: Double?
    let passCount: Int
    let failCount: Int
    let averageBody: Double?
    let averageCardio: Double?
    let averageStrength: Double?
    let averageCore: Double?
    let chronologicalScores: [ScorePoint]

    init(records: [PFRARecord]) {
        recordCount = records.count
        passCount = records.filter(\.passed).count
        failCount = records.count - passCount

        latestScore = records.first?.compositeScore
        bestScore = records.map(\.compositeScore).max()
        previousScore = records.dropFirst().first?.compositeScore

        if let latest = latestScore, let previous = previousScore {
            deltaFromPrevious = latest - previous
        } else {
            deltaFromPrevious = nil
        }

        if records.isEmpty {
            averageScore = nil
            averageBody = nil
            averageCardio = nil
            averageStrength = nil
            averageCore = nil
            chronologicalScores = []
            return
        }

        averageScore = records.map(\.compositeScore).reduce(0, +) / Double(records.count)
        averageBody = records.map(\.bodyPoints).reduce(0, +) / Double(records.count)
        averageCardio = records.map(\.cardioPoints).reduce(0, +) / Double(records.count)
        averageStrength = records.map(\.strengthPoints).reduce(0, +) / Double(records.count)
        averageCore = records.map(\.corePoints).reduce(0, +) / Double(records.count)
        chronologicalScores = records.reversed().map {
            ScorePoint(date: $0.testedAt, score: $0.compositeScore, passed: $0.passed)
        }
    }

    var passRate: Double? {
        guard recordCount > 0 else { return nil }
        return Double(passCount) / Double(recordCount)
    }
}
