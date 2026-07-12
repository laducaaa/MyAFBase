package com.ryanladuca.myafbase.data.afi

import java.util.Locale

object AfiSearchQueryBuilder {
    fun ftsQueries(rawQuery: String): List<String> {
        val tokens = tokenize(rawQuery)
        if (tokens.isEmpty()) return emptyList()
        if (tokens.size == 1) return listOf("\"${escape(tokens[0])}\"*")
        val phrase = tokens.joinToString(" ") { escape(it) }
        val andClause = tokens.joinToString(" AND ") { "\"${escape(it)}\"*" }
        val orClause = tokens.joinToString(" OR ") { "\"${escape(it)}\"*" }
        return listOf("\"$phrase\"*", andClause, orClause)
    }

    private fun tokenize(rawQuery: String): List<String> =
        rawQuery.lowercase(Locale.US)
            .split(Regex("[^a-z0-9]+"))
            .filter { it.length >= 2 }

    private fun escape(token: String): String = token.replace("\"", "")
}
