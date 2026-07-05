import Foundation
import SwiftData

@Observable
final class WARTrackerStore {
    private let modelContext: ModelContext
    private(set) var changeToken = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Mutations

    @discardableResult
    func addEntry(
        baseID: String,
        date: Date,
        text: String,
        category: WARCategory,
        performanceFactor: WARPerformanceFactor?,
        tags: [String],
        impact: String?,
        beneficiary: String?,
        hours: Double?,
        memberType: WARMemberType
    ) -> WAREntry {
        let entry = WAREntry(
            baseID: baseID,
            date: date,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            performanceFactor: performanceFactor,
            tags: Self.normalize(tags),
            impact: Self.nilIfBlank(impact),
            beneficiary: Self.nilIfBlank(beneficiary),
            hours: hours,
            memberType: memberType
        )
        modelContext.insert(entry)
        save()
        return entry
    }

    func update(
        _ entry: WAREntry,
        date: Date,
        text: String,
        category: WARCategory,
        performanceFactor: WARPerformanceFactor?,
        tags: [String],
        impact: String?,
        beneficiary: String?,
        hours: Double?
    ) {
        entry.date = date
        entry.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.category = category
        entry.performanceFactor = performanceFactor
        entry.tags = Self.normalize(tags)
        entry.impact = Self.nilIfBlank(impact)
        entry.beneficiary = Self.nilIfBlank(beneficiary)
        entry.hours = hours
        entry.updatedAt = Date()
        save()
    }

    func delete(_ entry: WAREntry) {
        modelContext.delete(entry)
        save()
    }

    // MARK: - Queries

    func entries(for baseID: String, in range: ClosedRange<Date>) -> [WAREntry] {
        _ = changeToken
        let lower = range.lowerBound
        let upper = range.upperBound
        let descriptor = FetchDescriptor<WAREntry>(
            predicate: #Predicate { entry in
                entry.baseID == baseID && entry.date >= lower && entry.date <= upper
            },
            sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func entries(for baseID: String, on day: Date, calendar: Calendar = .current) -> [WAREntry] {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) else {
            return []
        }
        return entries(for: baseID, in: start...end)
    }

    func entryCount(for baseID: String, in range: ClosedRange<Date>) -> Int {
        entries(for: baseID, in: range).count
    }

    func allEntries(for baseID: String) -> [WAREntry] {
        let descriptor = FetchDescriptor<WAREntry>(
            predicate: #Predicate { $0.baseID == baseID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Every entry across every base — used by retention cleanup, which
    /// applies globally rather than per-installation.
    func allEntries() -> [WAREntry] {
        let descriptor = FetchDescriptor<WAREntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Award deadlines

    @discardableResult
    func addDeadline(baseID: String, title: String, dueDate: Date, notes: String?) -> WARAwardDeadline {
        let deadline = WARAwardDeadline(
            baseID: baseID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            notes: Self.nilIfBlank(notes)
        )
        modelContext.insert(deadline)
        save()
        return deadline
    }

    func updateDeadline(_ deadline: WARAwardDeadline, title: String, dueDate: Date, notes: String?) {
        deadline.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        deadline.dueDate = dueDate
        deadline.notes = Self.nilIfBlank(notes)
        deadline.updatedAt = Date()
        save()
    }

    func deleteDeadline(_ deadline: WARAwardDeadline) {
        modelContext.delete(deadline)
        save()
    }

    func deadlines(for baseID: String) -> [WARAwardDeadline] {
        _ = changeToken
        let descriptor = FetchDescriptor<WARAwardDeadline>(
            predicate: #Predicate { $0.baseID == baseID },
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allDeadlines() -> [WARAwardDeadline] {
        let descriptor = FetchDescriptor<WARAwardDeadline>(sortBy: [SortDescriptor(\.dueDate, order: .forward)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func upcomingDeadlines(for baseID: String, limit: Int = 3) -> [WARAwardDeadline] {
        deadlines(for: baseID)
            .filter { !$0.isPastDue }
            .prefix(limit)
            .map { $0 }
    }

    /// Previously used tags for this base, most-frequent first — powers
    /// lightweight autocomplete in the Quick Add sheet without a fixed taxonomy.
    func suggestedTags(for baseID: String, limit: Int = 12) -> [String] {
        var counts: [String: Int] = [:]
        for entry in allEntries(for: baseID) {
            for tag in entry.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .prefix(limit)
            .map(\.key)
    }

    // MARK: - Private

    private func save() {
        try? modelContext.save()
        changeToken += 1
    }

    private static func normalize(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in tags {
            let cleaned = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "#", with: "")
            guard !cleaned.isEmpty, !seen.contains(cleaned) else { continue }
            seen.insert(cleaned)
            result.append(cleaned)
        }
        return result
    }

    private static func nilIfBlank(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
