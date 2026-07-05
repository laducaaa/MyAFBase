import Foundation
import SwiftData

@Observable
final class AssignmentProfileStore {
    private let modelContext: ModelContext
    private(set) var changeToken = 0
    private var cachedProfiles: [String: AssignmentProfile] = [:]
    private var cachedToken = -1

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Memoized per base ID and invalidated by `changeToken` so views that
    /// read the profile multiple times per body evaluation (e.g. Home's
    /// assignment banner) don't trigger a redundant SwiftData fetch — or a
    /// redundant insert+save — on every read.
    func profile(for baseID: String) -> AssignmentProfile {
        if cachedToken != changeToken {
            cachedProfiles.removeAll()
            cachedToken = changeToken
        }

        if let cached = cachedProfiles[baseID] {
            return cached
        }

        let resolved: AssignmentProfile
        if let existing = fetch(baseID: baseID) {
            resolved = existing
        } else {
            let created = AssignmentProfile(baseID: baseID)
            modelContext.insert(created)
            try? modelContext.save()
            resolved = created
        }

        cachedProfiles[baseID] = resolved
        return resolved
    }

    func phase(for baseID: String) -> AssignmentSegment {
        profile(for: baseID).phase
    }

    func updatePhase(_ phase: AssignmentSegment, baseID: String) {
        let profile = fetch(baseID: baseID) ?? {
            let created = AssignmentProfile(baseID: baseID)
            modelContext.insert(created)
            return created
        }()
        profile.phaseRaw = phase.rawValue
        save(profile)
    }

    func updateReportDate(_ date: Date?, baseID: String) {
        let profile = profile(for: baseID)
        profile.reportDate = date.map { Calendar.current.startOfDay(for: $0) }
        save(profile)
    }

    func updatePCSDate(_ date: Date?, baseID: String) {
        let profile = profile(for: baseID)
        profile.pcsDate = date.map { Calendar.current.startOfDay(for: $0) }
        save(profile)
    }

    func daysUntilReport(for baseID: String, relativeTo now: Date = .now) -> Int? {
        guard let reportDate = profile(for: baseID).reportDate else { return nil }
        return daysUntil(reportDate, from: now)
    }

    func daysUntilPCS(for baseID: String, relativeTo now: Date = .now) -> Int? {
        guard let pcsDate = profile(for: baseID).pcsDate else { return nil }
        return daysUntil(pcsDate, from: now)
    }

    private func save(_ profile: AssignmentProfile) {
        profile.updatedAt = Date()
        try? modelContext.save()
        notifyProfileChanged()
    }

    private func notifyProfileChanged() {
        changeToken += 1
    }

    private func fetch(baseID: String) -> AssignmentProfile? {
        let id = baseID
        let descriptor = FetchDescriptor<AssignmentProfile>(
            predicate: #Predicate { $0.baseID == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func daysUntil(_ date: Date, from now: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: target).day ?? 0
    }
}
