package com.ryanladuca.myafbase

import com.ryanladuca.myafbase.data.db.WarEntryEntity
import com.ryanladuca.myafbase.domain.logic.WarDateRangePreset
import com.ryanladuca.myafbase.domain.logic.WarOutputBuilder
import com.ryanladuca.myafbase.domain.logic.WarOutputFormat
import com.ryanladuca.myafbase.domain.logic.WarOutputGrouping
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WarOutputBuilderTests {
    @Test
    fun build_chronological_plainText_includesBody() {
        val entries = listOf(
            WarEntryEntity(
                id = "1",
                baseId = "nellis",
                dateMillis = 1_700_000_000_000,
                title = "Led project",
                body = "Coordinated squadron training event.",
                category = "leadership",
                impact = "Improved readiness",
                hours = 2.0,
            ),
        )
        val range = WarOutputBuilder.dateRange(WarDateRangePreset.THIS_YEAR, nowMillis = 1_700_000_000_000)
        val filtered = WarOutputBuilder.entriesInRange(entries, range)
        val text = WarOutputBuilder.build(filtered, WarOutputGrouping.CHRONOLOGICAL, WarOutputFormat.PLAIN_TEXT)
        assertTrue(text.contains("Coordinated squadron training event."))
        assertTrue(text.contains("Impact: Improved readiness"))
    }

    @Test
    fun summary_countsEntriesAndHours() {
        val entries = listOf(
            WarEntryEntity("1", "b", 0, "A", "body", hours = 1.5),
            WarEntryEntity("2", "b", 0, "B", "body", hours = 2.0),
        )
        val summary = WarOutputBuilder.summary(entries)
        assertEquals(2, summary.totalEntries)
        assertEquals(3.5, summary.totalHours, 0.001)
    }
}
