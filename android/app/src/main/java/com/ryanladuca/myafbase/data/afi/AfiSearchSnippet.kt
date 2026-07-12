package com.ryanladuca.myafbase.data.afi

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import java.util.Locale

/**
 * Builds result excerpts centered on the first matched query term, with highlights.
 * Ported from iOS [AFISearchSnippet].
 */
object AfiSearchSnippet {
    private const val WINDOW_RADIUS = 180

    fun excerpt(text: String, query: String): String {
        val normalized = text
            .replace('\n', ' ')
            .replace(Regex("\\s{2,}"), " ")
            .trim()

        val tokens = tokens(query)
        val matchIndex = firstMatchIndex(normalized, tokens)
            ?: return normalized.take(WINDOW_RADIUS * 2).let { if (normalized.length > it.length) "$it…" else it }

        var windowStart = (matchIndex - WINDOW_RADIUS).coerceAtLeast(0)
        var windowEnd = (matchIndex + WINDOW_RADIUS).coerceAtMost(normalized.length)

        if (windowEnd - windowStart < WINDOW_RADIUS * 2) {
            windowStart = (windowEnd - WINDOW_RADIUS * 2).coerceAtLeast(0)
        }
        windowEnd = (windowStart + WINDOW_RADIUS * 2).coerceAtMost(normalized.length)

        var start = windowStart
        var end = windowEnd
        if (windowStart > 0) {
            normalized.indexOf(' ', windowStart).takeIf { it >= 0 }?.let { start = it + 1 }
        }
        if (windowEnd < normalized.length) {
            normalized.lastIndexOf(' ', windowEnd).takeIf { it > start }?.let { end = it }
        }

        val prefix = if (start > 0) "…" else ""
        val suffix = if (end < normalized.length) "…" else ""
        return prefix + normalized.substring(start, end) + suffix
    }

    fun highlightedExcerpt(text: String, query: String, highlightColor: Color): AnnotatedString =
        highlight(excerpt(text, query), query, highlightColor)

    fun highlight(text: String, query: String, highlightColor: Color): AnnotatedString {
        val tokens = tokens(query)
        if (tokens.isEmpty()) return AnnotatedString(text)

        val lower = text.lowercase(Locale.US)
        val ranges = mutableListOf<IntRange>()
        for (token in tokens) {
            val needle = token.lowercase(Locale.US)
            var index = 0
            while (index < lower.length) {
                val pos = lower.indexOf(needle, index)
                if (pos < 0) break
                ranges += pos until (pos + needle.length)
                index = pos + needle.length
            }
        }
        if (ranges.isEmpty()) return AnnotatedString(text)

        val highlighted = BooleanArray(text.length)
        ranges.forEach { range ->
            for (i in range) {
                if (i in highlighted.indices) highlighted[i] = true
            }
        }

        return buildAnnotatedString {
            var i = 0
            while (i < text.length) {
                if (!highlighted[i]) {
                    val start = i
                    while (i < text.length && !highlighted[i]) i++
                    append(text.substring(start, i))
                    continue
                }
                val start = i
                while (i < text.length && highlighted[i]) i++
                pushStyle(SpanStyle(fontWeight = FontWeight.SemiBold, color = highlightColor))
                append(text.substring(start, i))
                pop()
            }
        }
    }

    fun tokens(query: String): List<String> =
        query.lowercase(Locale.US)
            .split(Regex("[^a-z0-9]+"))
            .filter { it.length >= 2 }

    private fun firstMatchIndex(text: String, tokens: List<String>): Int? {
        val lower = text.lowercase(Locale.US)
        return tokens.mapNotNull { token ->
            val pos = lower.indexOf(token.lowercase(Locale.US))
            if (pos >= 0) pos else null
        }.minOrNull()
    }
}
