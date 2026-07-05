import Foundation

/// Pure text-generation helpers for the WAR Tracker Reports screen. Kept free
/// of SwiftUI/SwiftData so it's trivially unit-testable.
enum WAROutputBuilder {
    static func summary(for entries: [WAREntry]) -> WAROutputSummary {
        guard !entries.isEmpty else { return .empty }

        let totalHours = entries.reduce(0.0) { $0 + ($1.hours ?? 0) }

        var categoryTally: [WARCategory: Int] = [:]
        var factorTally: [WARPerformanceFactor: Int] = [:]
        for entry in entries {
            categoryTally[entry.category, default: 0] += 1
            if let factor = entry.performanceFactor {
                factorTally[factor, default: 0] += 1
            }
        }

        let categoryCounts = WARCategory.allCases
            .compactMap { category -> (WARCategory, Int)? in
                guard let count = categoryTally[category] else { return nil }
                return (category, count)
            }
            .sorted { $0.1 > $1.1 }

        let factorCounts = WARPerformanceFactor.allCases
            .compactMap { factor -> (WARPerformanceFactor, Int)? in
                guard let count = factorTally[factor] else { return nil }
                return (factor, count)
            }
            .sorted { $0.1 > $1.1 }

        return WAROutputSummary(
            totalEntries: entries.count,
            totalHours: totalHours,
            categoryCounts: categoryCounts,
            factorCounts: factorCounts
        )
    }

    static func build(
        entries: [WAREntry],
        grouping: WAROutputGrouping,
        format: WAROutputFormat
    ) -> String {
        guard !entries.isEmpty else {
            return "No entries in this date range yet."
        }

        let sorted = entries.sorted { lhs, rhs in
            lhs.date != rhs.date ? lhs.date < rhs.date : lhs.createdAt < rhs.createdAt
        }

        switch grouping {
        case .chronological:
            return sorted.map { line(for: $0, format: format) }.joined(separator: "\n\n")
        case .category:
            return groupedBlocks(sorted, format: format) { $0.category.title }
        case .performanceFactor:
            return groupedBlocks(sorted, format: format) { $0.performanceFactor?.title ?? "Unmapped" }
        }
    }

    // MARK: - Private

    private static func groupedBlocks(
        _ entries: [WAREntry],
        format: WAROutputFormat,
        keyFor: (WAREntry) -> String
    ) -> String {
        var order: [String] = []
        var groups: [String: [WAREntry]] = [:]
        for entry in entries {
            let key = keyFor(entry)
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(entry)
        }

        return order.map { key -> String in
            let header = "\(key.uppercased())"
            let body = (groups[key] ?? []).map { line(for: $0, format: format) }.joined(separator: "\n\n")
            return "\(header)\n\(body)"
        }.joined(separator: "\n\n\n")
    }

    private static func line(for entry: WAREntry, format: WAROutputFormat) -> String {
        switch format {
        case .plainText: plainTextBlock(for: entry)
        case .draftBullets: bulletLine(for: entry)
        }
    }

    private static func plainTextBlock(for entry: WAREntry) -> String {
        var lines: [String] = []
        lines.append("\(dateLabel(entry.date)) — \(entry.category.title)")
        lines.append(entry.text)
        if let impact = entry.impact, !impact.isEmpty {
            lines.append("Impact: \(impact)")
        }
        if let beneficiary = entry.beneficiary, !beneficiary.isEmpty {
            lines.append("Benefited: \(beneficiary)")
        }
        if let hours = entry.hours, hours > 0 {
            lines.append("Hours: \(hoursLabel(hours))")
        }
        if !entry.tags.isEmpty {
            lines.append(entry.tags.map { "#\($0)" }.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }

    private static func bulletLine(for entry: WAREntry) -> String {
        var text = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let impact = entry.impact, !impact.isEmpty {
            text += "; \(impact.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        if let hours = entry.hours, hours > 0 {
            text += " (\(hoursLabel(hours)))"
        }
        return "- \(dateLabel(entry.date)): \(text)"
    }

    private static func dateLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private static func hoursLabel(_ hours: Double) -> String {
        hours == hours.rounded() ? "\(Int(hours))h" : String(format: "%.1fh", hours)
    }

    // MARK: - Award nomination draft

    static func nominationDraft(
        entries: [WAREntry],
        awardName: String,
        tone: WARCitationTone,
        level: WARAwardLevel,
        memberType: WARMemberType
    ) -> String {
        guard !entries.isEmpty else {
            return "No entries in this date range yet — pick a wider range or log a few accomplishments first."
        }

        let sorted = entries.sorted { $0.date < $1.date }
        let name = awardName.trimmingCharacters(in: .whitespacesAndNewlines)
        let award = name.isEmpty ? "this nomination" : name

        let opening = openingLine(award: award, tone: tone, level: level, memberType: memberType)
        let bullets = sorted.map { "  • \(nominationBullet(for: $0))" }.joined(separator: "\n")
        let closing = closingLine(tone: tone)

        return [opening, "", bullets, "", closing].joined(separator: "\n")
    }

    private static func openingLine(
        award: String,
        tone: WARCitationTone,
        level: WARAwardLevel,
        memberType: WARMemberType
    ) -> String {
        let member = memberType.title.lowercased()
        switch tone {
        case .concise:
            return "Nominated for \(award) (\(level.title) level). Key accomplishments:"
        case .standard:
            return "This \(member) is nominated for \(award) at the \(level.title) level based on the following accomplishments:"
        case .formal:
            return "It is with distinction that this \(member) is nominated for \(award) at the \(level.title) level, "
                + "in recognition of the sustained excellence reflected in the accomplishments below:"
        }
    }

    private static func nominationBullet(for entry: WAREntry) -> String {
        var text = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let impact = entry.impact, !impact.isEmpty {
            text += " — resulting in \(impact.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        if let hours = entry.hours, hours > 0 {
            text += " (\(hoursLabel(hours)))"
        }
        return text
    }

    private static func closingLine(tone: WARCitationTone) -> String {
        switch tone {
        case .concise:
            return "These achievements reflect strong performance and mission impact."
        case .standard:
            return "Taken together, these accomplishments reflect exceptional duty performance and a direct, "
                + "positive impact on mission readiness."
        case .formal:
            return "The initiative, professionalism, and mission focus demonstrated throughout this period "
                + "distinguish this individual as clearly deserving of this recognition."
        }
    }
}
