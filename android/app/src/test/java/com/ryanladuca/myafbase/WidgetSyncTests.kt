package com.ryanladuca.myafbase

import com.ryanladuca.myafbase.data.afi.AfiEmbeddingMath
import com.ryanladuca.myafbase.data.afi.AfiEmbeddingService
import com.ryanladuca.myafbase.data.afi.AfiSearchQueryBuilder
import com.ryanladuca.myafbase.data.afi.AfiSearchSnippet
import com.ryanladuca.myafbase.domain.logic.OpenNowCatalog
import com.ryanladuca.myafbase.domain.logic.PayCalendar
import com.ryanladuca.myafbase.domain.logic.SpecialPayEntry
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.Gate
import com.ryanladuca.myafbase.domain.model.Resource
import com.ryanladuca.myafbase.widget.PayWidgetBuilder
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetSyncTests {
    @Test
    fun payWidgetBuilder_includesSpecialPay() {
        val special = SpecialPayEntry("s1", "SDAP", System.currentTimeMillis() + 86_400_000L * 3, null)
        val snapshot = PayWidgetBuilder.snapshot(specialPays = listOf(special))
        assertTrue(snapshot.isAvailable)
        assertTrue(snapshot.upcoming.any { it.isSpecial })
    }
}

class OpenNowCatalogTests {
    @Test
    fun openEntries_filtersAlwaysOpenGates() {
        val base = Base(
            id = "test",
            name = "Test Base",
            gates = listOf(
                Gate(id = "g1", name = "Main Gate", hours = "Open 24/7"),
            ),
            resources = listOf(
                Resource(id = "r1", name = "DFAC", category = "dining", hours = "Open 24/7"),
            ),
        )
        val entries = OpenNowCatalog.openEntries(base)
        assertTrue(entries.any { it.name == "Main Gate" })
        assertTrue(entries.any { it.name == "DFAC" })
    }
}

class AfiEmbeddingTests {
    @Test
    fun embed_producesNormalizedVector() {
        val vector = AfiEmbeddingService.embed("leave policy convalescent") ?: floatArrayOf()
        assertEquals(AfiEmbeddingService.EMBEDDING_DIMENSION, vector.size)
        val selfSimilarity = AfiEmbeddingMath.cosineSimilarity(vector, vector)
        assertTrue(selfSimilarity > 0.99f)
    }

    @Test
    fun serializeRoundTrip() {
        val original = AfiEmbeddingService.embed("dress and appearance") ?: return
        val data = AfiEmbeddingService.serialize(original)
        val decoded = AfiEmbeddingService.deserialize(data)
        assertEquals(original.size, decoded?.size)
    }

    @Test
    fun ftsQueries_buildsPhraseAndAndVariants() {
        val queries = AfiSearchQueryBuilder.ftsQueries("convalescent leave")
        assertTrue(queries.size >= 2)
        assertTrue(queries.first().contains("convalescent"))
    }
}

class AfiSearchSnippetTests {
    @Test
    fun excerpt_centersOnMatch() {
        val text = "Alpha beta convalescent leave policy for members."
        val excerpt = AfiSearchSnippet.excerpt(text, "convalescent leave")
        assertTrue(excerpt.contains("convalescent", ignoreCase = true))
    }

    @Test
    fun tokens_filtersShortWords() {
        val tokens = AfiSearchSnippet.tokens("a PT test")
        assertEquals(listOf("pt", "test"), tokens)
    }
}
