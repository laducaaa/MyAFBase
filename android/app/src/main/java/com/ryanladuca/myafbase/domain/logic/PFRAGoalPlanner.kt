package com.ryanladuca.myafbase.domain.logic

import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

enum class PFRATargetTier(val title: String, val subtitle: String, val compositeThreshold: Double) {
    SATISFACTORY("Satisfactory", "75.0 composite minimum", PFRAScoring.PASS_COMPOSITE),
    EXCELLENT("Excellent", "90.0 composite", 90.0)
}

enum class PFRARecordKind(val title: String, val subtitle: String) {
    DIAGNOSTIC("Diagnostic", "Practice or unofficial check"),
    OFFICIAL("Official", "Recorded fitness assessment"),
    GOAL_PLANNING("Goal / Planning", "Working toward a target")
}

data class PFRAComponentTarget(
    val name: String,
    val currentPoints: Double,
    val requiredPoints: Double,
    val currentDetail: String,
    val targetDetail: String,
    val needsImprovement: Boolean
) {
    val pointsGap: Double get() = max(0.0, requiredPoints - currentPoints)
}

data class PFRATargetPlan(
    val target: PFRATargetTier,
    val currentComposite: Double,
    val targetComposite: Double,
    val alreadyMet: Boolean,
    val componentTargets: List<PFRAComponentTarget>,
    val notes: List<String>
) {
    val primaryFocus: PFRAComponentTarget?
        get() = componentTargets.filter { it.needsImprovement }.maxByOrNull { it.pointsGap }
}

object PFRAGoalPlanner {
    fun plan(
        target: PFRATargetTier,
        gender: PFRAGender,
        age: Int,
        heightInches: Double,
        waistInches: Double,
        cardioEvent: PFRACardioEvent,
        cardioValue: Double,
        strengthEvent: PFRAStrengthEvent,
        strengthReps: Int,
        coreEvent: PFRACoreEvent,
        coreValue: Double
    ): PFRATargetPlan? {
        if (heightInches <= 0 || waistInches <= 0) return null

        val current = PFRAScoring.evaluate(
            gender, age, heightInches, waistInches,
            cardioEvent, cardioValue, strengthEvent, strengthReps, coreEvent, coreValue
        )
        val targetComposite = target.compositeThreshold
        val alreadyMet = current.passed && current.compositeScore >= targetComposite
        val ageGroup = PFRAgeGroup.from(age)
        val notes = mutableListOf<String>()

        if (waistInches / heightInches >= 0.60) {
            notes += "Body composition fails at WHtR 0.60+. Reduce waist before other targets are reachable."
        }

        val componentTargets = current.componentScores.map { score ->
            buildComponentTarget(
                score, targetComposite, current.componentScores,
                gender, ageGroup, heightInches, waistInches,
                cardioEvent, cardioValue, strengthEvent, strengthReps, coreEvent, coreValue
            )
        }

        if (alreadyMet) {
            notes += "You already meet the ${target.title.lowercase()} threshold with your current inputs."
        } else {
            componentTargets.filter { it.needsImprovement }.maxByOrNull { it.pointsGap }?.let {
                notes += "Biggest gap: ${it.name} — need ${"%.1f".format(it.pointsGap)} more points there if other scores stay the same."
            }
        }

        return PFRATargetPlan(
            target = target,
            currentComposite = current.compositeScore,
            targetComposite = targetComposite,
            alreadyMet = alreadyMet,
            componentTargets = componentTargets,
            notes = notes
        )
    }

    private fun buildComponentTarget(
        score: PFRAComponentScore,
        targetComposite: Double,
        allScores: List<PFRAComponentScore>,
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        heightInches: Double,
        waistInches: Double,
        cardioEvent: PFRACardioEvent,
        cardioValue: Double,
        strengthEvent: PFRAStrengthEvent,
        strengthReps: Int,
        coreEvent: PFRACoreEvent,
        coreValue: Double
    ): PFRAComponentTarget {
        val minimum = if (score.name == "Cardio") PFRAScoring.CARDIO_MINIMUM else PFRAScoring.COMPONENT_MINIMUM
        val otherPoints = allScores.filter { it.name != score.name }.sumOf { it.points }
        val pointsForComposite = max(0.0, targetComposite - otherPoints)
        val requiredPoints = min(score.maxPoints, max(minimum, pointsForComposite))
        val targetDetail = performanceTarget(
            score.name, requiredPoints, gender, ageGroup,
            heightInches, waistInches, cardioEvent, strengthEvent, coreEvent
        )
        val needsImprovement = !score.passed || score.points < requiredPoints - 0.05
        return PFRAComponentTarget(
            name = score.name,
            currentPoints = score.points,
            requiredPoints = requiredPoints,
            currentDetail = score.detail,
            targetDetail = targetDetail,
            needsImprovement = needsImprovement
        )
    }

    private fun performanceTarget(
        componentName: String,
        requiredPoints: Double,
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        heightInches: Double,
        waistInches: Double,
        cardioEvent: PFRACardioEvent,
        strengthEvent: PFRAStrengthEvent,
        coreEvent: PFRACoreEvent
    ): String = when (componentName) {
        "Cardio" -> {
            val value = PFRAScoring.performanceForCardioPoints(
                gender, ageGroup, cardioEvent, requiredPoints
            ) ?: return "Improve cardio performance"
            when (cardioEvent) {
                PFRACardioEvent.TWO_MILE_RUN ->
                    "Run 2-mile in ${PFRAScoring.formatRunTime(value)} or faster (${"%.1f".format(requiredPoints)} pts)"
                PFRACardioEvent.HAMR ->
                    "Complete ${ceil(value).toInt()}+ HAMR shuttles (${"%.1f".format(requiredPoints)} pts)"
            }
        }
        "Body Composition" -> {
            val waist = PFRAScoring.waistInchesForWHtRPoints(heightInches, requiredPoints)
                ?: return "Reduce waist below fail threshold"
            val ratio = waist / heightInches
            "Waist ${"%.1f".format(waist)}\" or less (WHtR ${"%.2f".format(ratio)}, ${"%.1f".format(requiredPoints)} pts)"
        }
        "Strength" -> {
            val reps = PFRAScoring.performanceForStrengthPoints(
                gender, ageGroup, strengthEvent, requiredPoints
            ) ?: return "Increase ${strengthEvent.title.lowercase()}"
            "${ceil(reps).toInt()}+ reps on ${strengthEvent.title.lowercase()} (${"%.1f".format(requiredPoints)} pts)"
        }
        "Core" -> {
            val value = PFRAScoring.performanceForCorePoints(
                gender, ageGroup, coreEvent, requiredPoints
            ) ?: return "Improve ${coreEvent.title.lowercase()}"
            when (coreEvent) {
                PFRACoreEvent.SIT_UPS, PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH ->
                    "${ceil(value).toInt()}+ reps on ${coreEvent.title.lowercase()} (${"%.1f".format(requiredPoints)} pts)"
                PFRACoreEvent.FOREARM_PLANK ->
                    "Hold plank ${PFRAScoring.formatPlankTime(value)} or longer (${"%.1f".format(requiredPoints)} pts)"
            }
        }
        else -> "Reach ${"%.1f".format(requiredPoints)} points"
    }
}

data class PFRATrendsSummary(
    val count: Int,
    val bestScore: Double?,
    val latestScore: Double?,
    val averageScore: Double?,
    val passRate: Double?,
    val deltaFromPrevious: Double?,
    val passStreak: Int,
)

data class PFRAComponentAverage(
    val name: String,
    val average: Double,
    val maxPoints: Double,
)

data class PfraRecordSnapshot(
    val id: String,
    val dateMillis: Long,
    val score: Double,
    val passed: Boolean,
    val components: Map<String, Double>,
)

object PFRATrends {
    fun summarize(scoresNewestFirst: List<Pair<Double, Boolean>>): PFRATrendsSummary {
        if (scoresNewestFirst.isEmpty()) {
            return PFRATrendsSummary(0, null, null, null, null, null, 0)
        }
        val best = scoresNewestFirst.maxOf { it.first }
        val latest = scoresNewestFirst.first().first
        val average = scoresNewestFirst.map { it.first }.average()
        val passRate = scoresNewestFirst.count { it.second }.toDouble() / scoresNewestFirst.size
        val delta = if (scoresNewestFirst.size >= 2) {
            latest - scoresNewestFirst[1].first
        } else {
            null
        }
        var streak = 0
        for ((_, passed) in scoresNewestFirst) {
            if (passed) streak++ else break
        }
        return PFRATrendsSummary(
            count = scoresNewestFirst.size,
            bestScore = best,
            latestScore = latest,
            averageScore = average,
            passRate = passRate,
            deltaFromPrevious = delta,
            passStreak = streak,
        )
    }

    fun componentAverages(detailsNewestFirst: List<String>): List<PFRAComponentAverage> {
        val buckets = linkedMapOf(
            "Body Composition" to mutableListOf<Double>(),
            "Cardio" to mutableListOf(),
            "Strength" to mutableListOf(),
            "Core" to mutableListOf(),
        )
        detailsNewestFirst.forEach { details ->
            parseComponentDetails(details).forEach { (name, points) ->
                buckets[name]?.add(points)
            }
        }
        val maxPoints = mapOf(
            "Body Composition" to 20.0,
            "Cardio" to 50.0,
            "Strength" to 15.0,
            "Core" to 15.0,
        )
        return buckets.mapNotNull { (name, values) ->
            if (values.isEmpty()) {
                null
            } else {
                PFRAComponentAverage(name, values.average(), maxPoints[name] ?: 60.0)
            }
        }
    }

    fun parseComponentDetails(detailsJson: String): List<Pair<String, Double>> =
        detailsJson.split("|").mapNotNull { part ->
            val bits = part.split(":")
            if (bits.size < 2) return@mapNotNull null
            val name = bits[0].trim()
            val points = bits[1].toDoubleOrNull() ?: return@mapNotNull null
            name to points
        }

    fun comparisonInsights(
        records: List<PfraRecordSnapshot>,
        shortDate: (Long) -> String,
    ): List<String> {
        if (records.size < 2) return emptyList()
        val newest = records[0]
        val previous = records[1]
        val insights = mutableListOf<String>()
        val compositeDelta = newest.score - previous.score
        when {
            kotlin.math.abs(compositeDelta) < 0.05 ->
                insights.add("Composite is unchanged at ${"%.1f".format(newest.score)}.")
            compositeDelta > 0 ->
                insights.add(
                    "Composite improved by ${"%.1f".format(compositeDelta)} points since ${shortDate(previous.dateMillis)}.",
                )
            else ->
                insights.add(
                    "Composite dropped ${"%.1f".format(kotlin.math.abs(compositeDelta))} points since ${shortDate(previous.dateMillis)}.",
                )
        }
        val components = listOf("Body Composition", "Cardio", "Strength", "Core")
        val deltas = components.mapNotNull { name ->
            val newValue = newest.components[name] ?: return@mapNotNull null
            val oldValue = previous.components[name] ?: return@mapNotNull null
            (if (name == "Body Composition") "Body" else name) to (newValue - oldValue)
        }
        deltas.maxByOrNull { it.second }?.takeIf { it.second > 0.2 }?.let {
            insights.add("Biggest gain: ${it.first} (+${"%.1f".format(it.second)}).")
        }
        deltas.minByOrNull { it.second }?.takeIf { it.second < -0.2 }?.let {
            insights.add("Biggest drop: ${it.first} (${"%.1f".format(it.second)}).")
        }
        if (newest.passed && !previous.passed) {
            insights.add("You moved from not passing to passing.")
        } else if (!newest.passed && previous.passed) {
            insights.add("This score is below the pass standard after a previous pass.")
        }
        newest.components.minByOrNull { it.value }?.let {
            val label = if (it.key == "Body Composition") "Body" else it.key
            insights.add("Current focus area: $label at ${"%.1f".format(it.value)} points.")
        }
        return insights.take(4)
    }
}

