import Foundation
import SwiftUI

/// Builds result excerpts: a window of text centered on the first matched query term,
/// with every matched term highlighted.
enum AFISearchSnippet {
    /// Characters shown around the first match.
    nonisolated private static let windowRadius = 180

    nonisolated static func excerpt(from text: String, query: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let tokens = tokens(from: query)
        guard let matchRange = firstMatchRange(in: normalized, tokens: tokens) else {
            return String(normalized.prefix(windowRadius * 2))
        }

        let matchStart = normalized.distance(from: normalized.startIndex, to: matchRange.lowerBound)
        var windowStart = max(0, matchStart - windowRadius)
        var windowEnd = min(normalized.count, matchStart + windowRadius)

        // Expand a short tail window backwards so excerpts stay a consistent length.
        if windowEnd - windowStart < windowRadius * 2 {
            windowStart = max(0, windowEnd - windowRadius * 2)
        }
        windowEnd = min(normalized.count, windowStart + windowRadius * 2)

        var start = normalized.index(normalized.startIndex, offsetBy: windowStart)
        var end = normalized.index(normalized.startIndex, offsetBy: windowEnd)

        // Snap to word boundaries.
        if windowStart > 0, let space = normalized[start...].firstIndex(of: " ") {
            start = normalized.index(after: space)
        }
        if windowEnd < normalized.count, let space = normalized[..<end].lastIndex(of: " ") {
            end = space
        }

        var excerpt = String(normalized[start ..< end])
        if windowStart > 0 { excerpt = "…" + excerpt }
        if windowEnd < normalized.count { excerpt += "…" }
        return excerpt
    }

    /// The excerpt with query terms emphasized for display.
    nonisolated static func highlightedExcerpt(
        from text: String,
        query: String,
        highlightColor: Color
    ) -> AttributedString {
        highlight(excerpt(from: text, query: query), query: query, highlightColor: highlightColor)
    }

    /// Emphasizes every query term occurrence in the given text.
    nonisolated static func highlight(
        _ text: String,
        query: String,
        highlightColor: Color
    ) -> AttributedString {
        var attributed = AttributedString(text)

        for token in tokens(from: query) {
            var searchStart = text.startIndex
            while let range = text.range(
                of: token,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart ..< text.endIndex
            ) {
                if let attributedRange = Range(range, in: attributed) {
                    attributed[attributedRange].font = .subheadline.weight(.semibold)
                    attributed[attributedRange].foregroundColor = highlightColor
                }
                searchStart = range.upperBound
            }
        }

        return attributed
    }

    nonisolated static func tokens(from query: String) -> [String] {
        query
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
    }

    private nonisolated static func firstMatchRange(
        in text: String,
        tokens: [String]
    ) -> Range<String.Index>? {
        var earliest: Range<String.Index>?
        for token in tokens {
            guard let range = text.range(of: token, options: [.caseInsensitive, .diacriticInsensitive]) else {
                continue
            }
            if earliest == nil || range.lowerBound < earliest!.lowerBound {
                earliest = range
            }
        }
        return earliest
    }
}
