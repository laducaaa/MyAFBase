package com.ryanladuca.myafbase.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import com.ryanladuca.myafbase.data.db.ReadinessEntity
import com.ryanladuca.myafbase.data.db.SpecialPayEntity
import com.ryanladuca.myafbase.data.db.WarEntryEntity
import com.ryanladuca.myafbase.data.repository.WeatherSnapshot
import com.ryanladuca.myafbase.domain.logic.OpenNowCatalog
import com.ryanladuca.myafbase.domain.logic.PayCalendar
import com.ryanladuca.myafbase.domain.logic.ReadinessStatus
import com.ryanladuca.myafbase.domain.logic.SpecialPayEntry
import com.ryanladuca.myafbase.domain.logic.WarDateMath
import com.ryanladuca.myafbase.domain.logic.HoursParser
import com.ryanladuca.myafbase.domain.model.Base
import com.ryanladuca.myafbase.domain.model.BookmarkTargetType
import com.ryanladuca.myafbase.domain.model.EmergencyNumber
import com.ryanladuca.myafbase.domain.model.ResolvedBookmark
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.abs
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

object WidgetKinds {
    const val PAY = "PayGlanceWidget"
    const val WEATHER = "WeatherGlanceWidget"
    const val OPEN_NOW = "OpenNowGlanceWidget"
    const val EMERGENCY = "EmergencyGlanceWidget"
    const val READINESS = "ReadinessGlanceWidget"
    const val WAR_QUICK_LOG = "WarQuickLogGlanceWidget"
}

class WidgetSync(
    private val context: Context,
    private val dataStore: WidgetDataStore,
) {
    suspend fun publishAll(
        base: Base?,
        weather: WeatherSnapshot?,
        readiness: ReadinessEntity?,
        bookmarks: List<ResolvedBookmark>,
        specialPays: List<SpecialPayEntity>,
        warEntries: List<WarEntryEntity>,
    ) {
        if (base == null) return
        publishPay(specialPays)
        publishWeather(base, weather)
        publishOpenNow(base, bookmarks)
        publishEmergency(base)
        publishReadiness(base, readiness)
        publishWarTracker(base.id, warEntries)
    }

    suspend fun publishPay(specialPays: List<SpecialPayEntity>) {
        val snapshot = PayWidgetBuilder.snapshot(
            specialPays = specialPays.map {
                SpecialPayEntry(it.id, it.title, it.dateMillis, it.notes)
            },
        )
        dataStore.savePay(snapshot)
        reloadWidgets()
    }

    suspend fun publishWeather(base: Base, weather: WeatherSnapshot?) {
        val snapshot = WeatherWidgetBuilder.snapshot(base, weather)
        dataStore.saveWeather(snapshot)
        reloadWidgets()
    }

    suspend fun publishOpenNow(base: Base, bookmarks: List<ResolvedBookmark>) {
        val snapshot = OpenNowWidgetBuilder.snapshot(base, bookmarks)
        dataStore.saveOpenNow(snapshot)
        reloadWidgets()
    }

    suspend fun publishEmergency(base: Base) {
        val snapshot = EmergencyWidgetBuilder.snapshot(base)
        dataStore.saveEmergency(snapshot)
        reloadWidgets()
    }

    suspend fun publishReadiness(base: Base, readiness: ReadinessEntity?) {
        if (readiness == null) return
        val snapshot = ReadinessCountdownBuilder.snapshot(readiness, base.name)
        dataStore.saveReadiness(snapshot)
        reloadWidgets()
    }

    suspend fun publishWarTracker(baseId: String, entries: List<WarEntryEntity>) {
        val now = System.currentTimeMillis()
        val weekStart = WarDateMath.startOfWeek(now)
        val weekEnd = WarDateMath.endOfDay(WarDateMath.addDays(weekStart, 6))
        val count = entries.count { it.baseId == baseId && it.dateMillis in weekStart..weekEnd }
        val snapshot = WarWidgetSnapshot(
            baseId = baseId,
            entriesThisWeek = count,
            weekRangeLabel = WarDateMath.rangeLabel(weekStart, weekEnd),
            updatedAtMillis = now,
        )
        dataStore.saveWarTracker(snapshot)
        reloadWidgets()
    }

    private suspend fun reloadWidgets() = withContext(Dispatchers.Main) {
        runCatching {
            PayGlanceWidget().updateAll(context)
            WeatherGlanceWidget().updateAll(context)
            OpenNowGlanceWidget().updateAll(context)
            EmergencyGlanceWidget().updateAll(context)
            ReadinessGlanceWidget().updateAll(context)
            WarQuickLogGlanceWidget().updateAll(context)
        }
    }
}

object PayWidgetBuilder {
    fun snapshot(
        fromMillis: Long = System.currentTimeMillis(),
        specialPays: List<SpecialPayEntry> = emptyList(),
    ): PayWidgetSnapshot {
        val events = PayCalendar.upcomingEvents(fromMillis = fromMillis, specialPays = specialPays)
        val next = events.firstOrNull()
            ?: return PayWidgetSnapshot(
                nextTitle = "",
                nextDateMillis = fromMillis,
                daysUntil = 0,
                isSpecial = false,
                symbolName = "pay",
                upcoming = emptyList(),
                updatedAtMillis = fromMillis,
            )

        val upcoming = events.take(4).map { event ->
            PayWidgetUpcomingItem(
                title = event.title,
                dateMillis = event.dateMillis,
                daysUntil = PayCalendar.daysUntil(event.dateMillis, fromMillis),
                isSpecial = event.isSpecial,
                symbolName = if (event.isSpecial) "star" else "pay",
            )
        }

        return PayWidgetSnapshot(
            nextTitle = next.title,
            nextDateMillis = next.dateMillis,
            daysUntil = PayCalendar.daysUntil(next.dateMillis, fromMillis),
            isSpecial = next.isSpecial,
            symbolName = if (next.isSpecial) "star" else "pay",
            upcoming = upcoming,
            updatedAtMillis = fromMillis,
        )
    }
}

object WeatherWidgetBuilder {
    fun snapshot(base: Base, weather: WeatherSnapshot?): WeatherWidgetSnapshot {
        if (weather == null || weather.isPlaceholder) {
            return WeatherWidgetSnapshot(
                baseId = base.id,
                baseName = base.name,
                location = base.location,
                tempF = null,
                feelsLikeF = null,
                conditionName = "Unavailable",
                symbolName = "cloud",
                windMph = null,
                humidity = null,
                isAvailable = false,
                updatedAtMillis = System.currentTimeMillis(),
            )
        }
        return WeatherWidgetSnapshot(
            baseId = base.id,
            baseName = base.name,
            location = base.location,
            tempF = weather.tempF?.toInt(),
            feelsLikeF = weather.feelsLikeDisplayF(),
            conditionName = weather.conditionLabel,
            symbolName = weather.condition.themeKey,
            windMph = weather.windMph?.toInt(),
            humidity = weather.humidity,
            isAvailable = true,
            updatedAtMillis = weather.lastUpdatedMillis,
        )
    }
}

object OpenNowWidgetBuilder {
    fun snapshot(base: Base, savedItems: List<ResolvedBookmark>, limit: Int = 8): OpenNowWidgetSnapshot {
        val items = OpenNowCatalog.openEntries(base).take(limit).map { entry ->
            OpenNowWidgetItemSnapshot(
                id = entry.id,
                name = entry.name,
                categoryLabel = entry.categoryLabel,
                systemImage = entry.systemImage,
                detail = entry.detail,
                statusLabel = "Open",
                isOpen = true,
            )
        }
        val bookmarks = savedItems.mapNotNull { buildBookmarkItem(it) }
        return OpenNowWidgetSnapshot(
            baseId = base.id,
            baseName = base.name,
            items = items,
            bookmarks = bookmarks,
            updatedAtMillis = System.currentTimeMillis(),
        )
    }

    private fun buildBookmarkItem(item: ResolvedBookmark): OpenNowWidgetItemSnapshot? = when (item) {
        is ResolvedBookmark.GateItem -> {
            val gate = item.gate
            val isOpen = !gate.status.equals("closed", ignoreCase = true) &&
                (HoursParser.isOpenNow(gate.hours) ?: true)
            OpenNowWidgetItemSnapshot(
                id = "${BookmarkTargetType.GATE.raw}-${gate.id}",
                name = gate.name,
                categoryLabel = "Gate",
                systemImage = "gate",
                detail = gate.hours.takeIf { it.isNotBlank() },
                statusLabel = if (isOpen) "Open" else "Closed",
                isOpen = isOpen,
            )
        }
        is ResolvedBookmark.ResourceItem -> {
            val resource = item.resource
            val open = HoursParser.isOpenNow(resource.displayHours)
            OpenNowWidgetItemSnapshot(
                id = "${BookmarkTargetType.RESOURCE.raw}-${resource.id}",
                name = resource.name,
                categoryLabel = resource.category.replaceFirstChar { it.uppercase() },
                systemImage = "resource",
                detail = resource.displayHours,
                statusLabel = when (open) {
                    true -> "Open"
                    false -> "Closed"
                    null -> "Hours unavailable"
                },
                isOpen = open ?: false,
            )
        }
        is ResolvedBookmark.EventItem -> {
            val event = item.event
            OpenNowWidgetItemSnapshot(
                id = "${BookmarkTargetType.EVENT.raw}-${event.id}",
                name = event.title,
                categoryLabel = event.category?.replaceFirstChar { it.uppercase() } ?: "Event",
                systemImage = "event",
                detail = event.date,
                statusLabel = "Event",
                isOpen = true,
            )
        }
        is ResolvedBookmark.Orphan -> null
    }
}

object EmergencyWidgetBuilder {
    fun snapshot(base: Base): EmergencyWidgetSnapshot {
        return EmergencyWidgetSnapshot(
            baseId = base.id,
            baseName = base.name,
            contacts = prioritize(base.emergencyNumbers).map(::contactSnapshot),
            updatedAtMillis = System.currentTimeMillis(),
        )
    }

    fun prioritize(numbers: List<EmergencyNumber>): List<EmergencyNumber> {
        val result = mutableListOf<EmergencyNumber>()
        val remaining = numbers.toMutableList()

        fun take(predicate: (EmergencyNumber) -> Boolean) {
            val index = remaining.indexOfFirst(predicate)
            if (index >= 0) result += remaining.removeAt(index)
        }

        take { it.number.filter(Char::isDigit) == "911" }
        take { it.label.contains("security", ignoreCase = true) }
        take {
            it.label.contains("hospital", ignoreCase = true) ||
                it.label.contains("medical", ignoreCase = true)
        }
        take { it.label.contains("fire", ignoreCase = true) }
        result += remaining
        return result
    }

    private fun contactSnapshot(number: EmergencyNumber): EmergencyContactSnapshot {
        val isUniversal = number.number.filter(Char::isDigit) == "911"
        val label = if (isUniversal) "911" else number.label
        val image = when {
            isUniversal -> "emergency"
            number.label.contains("medical", ignoreCase = true) ||
                number.label.contains("hospital", ignoreCase = true) -> "medical"
            number.label.contains("fire", ignoreCase = true) -> "fire"
            number.label.contains("security", ignoreCase = true) -> "security"
            else -> "phone"
        }
        return EmergencyContactSnapshot(
            id = number.id,
            label = label,
            number = number.number,
            systemImage = image,
            isUniversalEmergency = isUniversal,
        )
    }
}

object ReadinessCountdownBuilder {
    private val dateFormat = SimpleDateFormat("MMM d, yyyy", Locale.US)

    private data class KindDef(val raw: String, val title: String, val image: String)

    private val kinds = listOf(
        KindDef("fitness", "Fitness test", "fitness"),
        KindDef("dental", "Dental", "dental"),
        KindDef("eval", "EPB/OPB closeout", "eval"),
        KindDef("cac", "CAC expiration", "cac"),
        KindDef("clearance", "Clearance renewal", "clearance"),
        KindDef("pcsWindow", "PCS window", "pcs"),
    )

    fun snapshot(readiness: ReadinessEntity, baseName: String, nowMillis: Long = System.currentTimeMillis()): ReadinessWidgetSnapshot {
        return ReadinessWidgetSnapshot(
            activeBaseId = readiness.baseId,
            activeBaseName = baseName,
            items = kinds.map { buildItem(it, readiness, nowMillis) },
            updatedAtMillis = readiness.updatedAtMillis,
        )
    }

    private fun buildItem(kind: KindDef, readiness: ReadinessEntity, nowMillis: Long): ReadinessWidgetItemSnapshot {
        return when (kind.raw) {
            "pcsWindow" -> pcsWindowItem(kind, readiness, nowMillis)
            else -> {
                val due = when (kind.raw) {
                    "fitness" -> readiness.fitnessTestDueMillis
                    "dental" -> readiness.dentalDueMillis
                    "eval" -> readiness.evalCloseoutDueMillis
                    "cac" -> readiness.cacExpirationMillis
                    "clearance" -> readiness.clearanceRenewalMillis
                    else -> null
                }
                dueDateItem(kind, due, nowMillis)
            }
        }
    }

    private fun dueDateItem(kind: KindDef, dueMillis: Long?, nowMillis: Long): ReadinessWidgetItemSnapshot {
        val status = ReadinessStatus.evaluate(dueMillis, nowMillis)
        if (dueMillis == null) {
            return ReadinessWidgetItemSnapshot(
                kind = kind.raw,
                title = kind.title,
                systemImage = kind.image,
                countdownValue = null,
                countdownLabel = "Not set",
                detailLabel = "Set in Assignment",
                statusRaw = status.widgetKey,
            )
        }
        val days = TimeUnit.MILLISECONDS.toDays(
            startOfDay(dueMillis) - startOfDay(nowMillis),
        ).toInt()
        val (value, label) = when {
            days < 0 -> {
                val overdue = abs(days)
                overdue to if (days == -1) "day overdue" else "days overdue"
            }
            days == 0 -> 0 to "due today"
            days == 1 -> 1 to "day"
            else -> days to "days"
        }
        return ReadinessWidgetItemSnapshot(
            kind = kind.raw,
            title = kind.title,
            systemImage = kind.image,
            countdownValue = value,
            countdownLabel = label,
            detailLabel = dateFormat.format(Date(dueMillis)),
            statusRaw = status.widgetKey,
        )
    }

    private fun pcsWindowItem(kind: KindDef, readiness: ReadinessEntity, nowMillis: Long): ReadinessWidgetItemSnapshot {
        val start = readiness.pcsWindowStartMillis
        val end = readiness.pcsWindowEndMillis
        val status = ReadinessStatus.evaluatePcsWindow(start, end, nowMillis)
        if (start == null || end == null) {
            return ReadinessWidgetItemSnapshot(
                kind = kind.raw,
                title = kind.title,
                systemImage = kind.image,
                countdownValue = null,
                countdownLabel = "Not set",
                detailLabel = "Set in Assignment",
                statusRaw = status.widgetKey,
            )
        }
        val detail = "${dateFormat.format(Date(start))} – ${dateFormat.format(Date(end))}"
        val today = startOfDay(nowMillis)
        val windowStart = startOfDay(start)
        val windowEnd = startOfDay(end)
        return when {
            today in windowStart..windowEnd -> {
                val daysLeft = TimeUnit.MILLISECONDS.toDays(windowEnd - today).toInt().coerceAtLeast(0)
                ReadinessWidgetItemSnapshot(
                    kind = kind.raw,
                    title = kind.title,
                    systemImage = kind.image,
                    countdownValue = daysLeft,
                    countdownLabel = if (daysLeft == 1) "day left" else "days left",
                    detailLabel = detail,
                    statusRaw = status.widgetKey,
                )
            }
            today > windowEnd -> {
                val overdue = TimeUnit.MILLISECONDS.toDays(today - windowEnd).toInt().coerceAtLeast(1)
                ReadinessWidgetItemSnapshot(
                    kind = kind.raw,
                    title = kind.title,
                    systemImage = kind.image,
                    countdownValue = overdue,
                    countdownLabel = if (overdue == 1) "day past" else "days past",
                    detailLabel = detail,
                    statusRaw = status.widgetKey,
                )
            }
            else -> {
                val until = TimeUnit.MILLISECONDS.toDays(windowStart - today).toInt().coerceAtLeast(0)
                ReadinessWidgetItemSnapshot(
                    kind = kind.raw,
                    title = kind.title,
                    systemImage = kind.image,
                    countdownValue = until,
                    countdownLabel = if (until == 1) "day until open" else "days until open",
                    detailLabel = detail,
                    statusRaw = status.widgetKey,
                )
            }
        }
    }

    private fun startOfDay(millis: Long): Long {
        val cal = java.util.Calendar.getInstance().apply { timeInMillis = millis }
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }
}

private val ReadinessStatus.widgetKey: String
    get() = when (this) {
        ReadinessStatus.NOT_SET -> "notSet"
        ReadinessStatus.OVERDUE -> "overdue"
        ReadinessStatus.DUE_SOON -> "dueSoon"
        ReadinessStatus.ON_TRACK -> "onTrack"
        ReadinessStatus.WINDOW_OPEN -> "windowOpen"
    }
