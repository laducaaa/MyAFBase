package com.ryanladuca.myafbase.domain.logic

import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

enum class PFRAGender { MALE, FEMALE }

enum class PFRAgeGroup(val title: String, val rawValue: Int) {
    UNDER_25("Under 25", 0),
    AGE_25_29("25–29", 1),
    AGE_30_34("30–34", 2),
    AGE_35_39("35–39", 3),
    AGE_40_44("40–44", 4),
    AGE_45_49("45–49", 5),
    AGE_50_54("50–54", 6),
    AGE_55_59("55–59", 7),
    SIXTY_PLUS("60+", 8);

    companion object {
        fun from(age: Int): PFRAgeGroup = when {
            age < 25 -> UNDER_25
            age < 30 -> AGE_25_29
            age < 35 -> AGE_30_34
            age < 40 -> AGE_35_39
            age < 45 -> AGE_40_44
            age < 50 -> AGE_45_49
            age < 55 -> AGE_50_54
            age < 60 -> AGE_55_59
            else -> SIXTY_PLUS
        }
    }
}

enum class PFRACardioEvent(val title: String) {
    TWO_MILE_RUN("2-Mile Run"),
    HAMR("20m HAMR")
}

enum class PFRAStrengthEvent(val title: String) {
    PUSH_UPS("Push-Ups (1 min)"),
    HAND_RELEASE_PUSH_UPS("Hand-Release Push-Ups (2 min)")
}

enum class PFRACoreEvent(val title: String) {
    SIT_UPS("Sit-Ups (1 min)"),
    CROSS_LEG_REVERSE_CRUNCH("Cross-Leg Reverse Crunch (2 min)"),
    FOREARM_PLANK("Forearm Plank")
}

data class PFRAComponentScore(
    val name: String,
    val points: Double,
    val maxPoints: Double,
    val passed: Boolean,
    val detail: String
)

data class PFRAResult(
    val compositeScore: Double,
    val passed: Boolean,
    val rating: String,
    val componentScores: List<PFRAComponentScore>,
    val guidance: List<String>
)

object PFRAScoring {
    const val PASS_COMPOSITE = 75.0
    const val COMPONENT_MINIMUM = 2.5
    const val CARDIO_MINIMUM = 35.0

    fun evaluate(
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
    ): PFRAResult {
        val ageGroup = PFRAgeGroup.from(age)
        val bodyScore = scoreWHtR(waistInches, heightInches)
        val cardioScore = scoreCardio(gender, ageGroup, cardioEvent, cardioValue)
        val strengthScore = scoreStrength(gender, ageGroup, strengthEvent, strengthReps)
        val coreScore = scoreCore(gender, ageGroup, coreEvent, coreValue)

        val componentScores = listOf(
            PFRAComponentScore("Cardio", cardioScore.points, 50.0, cardioScore.passed, cardioScore.detail),
            PFRAComponentScore("Body Composition", bodyScore.points, 20.0, bodyScore.passed, bodyScore.detail),
            PFRAComponentScore("Strength", strengthScore.points, 15.0, strengthScore.passed, strengthScore.detail),
            PFRAComponentScore("Core", coreScore.points, 15.0, coreScore.passed, coreScore.detail)
        )

        val composite = componentScores.sumOf { it.points }
        val allComponentsPassed = componentScores.all { it.passed }
        val passed = composite >= PASS_COMPOSITE && allComponentsPassed

        val rating = when {
            !allComponentsPassed || composite < PASS_COMPOSITE -> "Unsatisfactory"
            composite >= 90 -> "Excellent"
            else -> "Satisfactory"
        }

        val guidance = buildGuidance(
            componentScores, composite, gender, ageGroup, cardioEvent, strengthEvent, coreEvent
        )

        return PFRAResult(composite, passed, rating, componentScores, guidance)
    }

    // MARK: - WHtR

    private data class ComponentTriple(val points: Double, val passed: Boolean, val detail: String)

    private fun scoreWHtR(waist: Double, height: Double): ComponentTriple {
        if (height <= 0 || waist <= 0) return ComponentTriple(0.0, false, "Enter height and waist")

        val ratio = waist / height
        val formatted = "%.2f".format(ratio)

        if (ratio >= 0.60) return ComponentTriple(0.0, false, "WHtR $formatted — component fail")

        val breakpoints = listOf(
            0.49 to 20.0,
            0.55 to 12.5,
            0.59 to 2.5
        )

        if (ratio <= 0.49) return ComponentTriple(20.0, true, "WHtR $formatted")

        var points = 2.5
        for (index in 0 until breakpoints.size - 1) {
            val upper = breakpoints[index]
            val lower = breakpoints[index + 1]
            if (ratio > upper.first && ratio <= lower.first) {
                val progress = (lower.first - ratio) / (lower.first - upper.first)
                points = lower.second + progress * (upper.second - lower.second)
                break
            }
        }

        return ComponentTriple(points, points >= COMPONENT_MINIMUM, "WHtR $formatted")
    }

    // MARK: - Cardio

    private fun scoreCardio(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACardioEvent,
        value: Double
    ): ComponentTriple = when (event) {
        PFRACardioEvent.TWO_MILE_RUN -> {
            val best = interpolated(twoMileBest50(gender), twoMileBest50Old(gender), ageGroup)
            val minimum = interpolated(twoMileMin35(gender), twoMileMin35Old(gender), ageGroup)
            val points = scoreLowerIsBetter(value, best, minimum, 50.0, CARDIO_MINIMUM)
            ComponentTriple(points, points >= CARDIO_MINIMUM, "2-mile: ${formatRunTime(value)}")
        }
        PFRACardioEvent.HAMR -> {
            val minShuttles = interpolated(hamrMin35(gender), hamrMin35Old(gender), ageGroup)
            val maxShuttles = interpolated(hamrMax50(gender), hamrMax50Old(gender), ageGroup)
            val points = scoreHigherIsBetter(value, minShuttles, maxShuttles, 50.0, CARDIO_MINIMUM)
            ComponentTriple(points, points >= CARDIO_MINIMUM, "HAMR: ${value.toInt()} shuttles")
        }
    }

    // MARK: - Strength

    private fun scoreStrength(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRAStrengthEvent,
        reps: Int
    ): ComponentTriple {
        val value = reps.toDouble()
        val (minimum, maximum) = when (gender to event) {
            PFRAGender.MALE to PFRAStrengthEvent.PUSH_UPS ->
                interpolated(30.0, 12.0, ageGroup) to interpolated(67.0, 38.0, ageGroup)
            PFRAGender.FEMALE to PFRAStrengthEvent.PUSH_UPS ->
                interpolated(15.0, 3.0, ageGroup) to interpolated(50.0, 28.0, ageGroup)
            PFRAGender.MALE to PFRAStrengthEvent.HAND_RELEASE_PUSH_UPS ->
                interpolated(27.0, 11.0, ageGroup) to interpolated(52.0, 36.0, ageGroup)
            PFRAGender.FEMALE to PFRAStrengthEvent.HAND_RELEASE_PUSH_UPS ->
                interpolated(17.0, 1.0, ageGroup) to interpolated(42.0, 26.0, ageGroup)
            else -> 0.0 to 1.0
        }
        val points = scoreHigherIsBetter(value, minimum, maximum, 15.0, COMPONENT_MINIMUM)
        return ComponentTriple(points, points >= COMPONENT_MINIMUM, "$reps reps")
    }

    // MARK: - Core

    private fun scoreCore(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACoreEvent,
        value: Double
    ): ComponentTriple = when (event) {
        PFRACoreEvent.SIT_UPS, PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH -> {
            val (minimum, maximum) = when (gender to event) {
                PFRAGender.MALE to PFRACoreEvent.SIT_UPS ->
                    interpolated(33.0, 17.0, ageGroup) to interpolated(58.0, 42.0, ageGroup)
                PFRAGender.FEMALE to PFRACoreEvent.SIT_UPS ->
                    interpolated(29.0, 6.0, ageGroup) to interpolated(58.0, 31.0, ageGroup)
                PFRAGender.MALE to PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH ->
                    interpolated(35.0, 19.0, ageGroup) to interpolated(60.0, 44.0, ageGroup)
                PFRAGender.FEMALE to PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH ->
                    interpolated(33.0, 17.0, ageGroup) to interpolated(58.0, 42.0, ageGroup)
                else -> 0.0 to 1.0
            }
            val points = scoreHigherIsBetter(value, minimum, maximum, 15.0, COMPONENT_MINIMUM)
            ComponentTriple(points, points >= COMPONENT_MINIMUM, "${value.toInt()} reps")
        }
        PFRACoreEvent.FOREARM_PLANK -> {
            val minimum = interpolated(
                if (gender == PFRAGender.MALE) 95.0 else 90.0,
                if (gender == PFRAGender.MALE) 55.0 else 50.0,
                ageGroup
            )
            val maximum = interpolated(
                if (gender == PFRAGender.MALE) 220.0 else 215.0,
                if (gender == PFRAGender.MALE) 180.0 else 175.0,
                ageGroup
            )
            val points = scoreHigherIsBetter(value, minimum, maximum, 15.0, COMPONENT_MINIMUM)
            ComponentTriple(points, points >= COMPONENT_MINIMUM, formatPlankTime(value))
        }
    }

    // MARK: - Guidance

    private fun buildGuidance(
        componentScores: List<PFRAComponentScore>,
        composite: Double,
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        cardioEvent: PFRACardioEvent,
        strengthEvent: PFRAStrengthEvent,
        coreEvent: PFRACoreEvent
    ): List<String> {
        val tips = mutableListOf<String>()

        if (composite < PASS_COMPOSITE) {
            val deficit = PASS_COMPOSITE - composite
            tips += "You need ${"%.1f".format(deficit)} more composite points to reach 75."
        }

        componentScores.filter { !it.passed }.forEach { component ->
            tips += when (component.name) {
                "Cardio" -> cardioPassTip(gender, ageGroup, cardioEvent)
                "Body Composition" ->
                    "Reduce waist-to-height ratio below 0.59 (2.5 pts minimum). At 0.60+ the component fails."
                "Strength" -> strengthPassTip(gender, ageGroup, strengthEvent)
                "Core" -> corePassTip(gender, ageGroup, coreEvent)
                else -> return@forEach
            }
        }

        if (tips.isEmpty()) {
            tips += "You meet current estimated pass thresholds. Keep training for margin above 75."
        }

        return tips
    }

    private fun cardioPassTip(gender: PFRAGender, ageGroup: PFRAgeGroup, event: PFRACardioEvent): String =
        when (event) {
            PFRACardioEvent.TWO_MILE_RUN -> {
                val minimum = interpolated(twoMileMin35(gender), twoMileMin35Old(gender), ageGroup)
                "Run the 2-mile in ${formatRunTime(minimum)} or faster for at least 35 cardio points."
            }
            PFRACardioEvent.HAMR -> {
                val minShuttles = interpolated(hamrMin35(gender), hamrMin35Old(gender), ageGroup).roundToInt()
                "Complete at least $minShuttles HAMR shuttles for 35 cardio points."
            }
        }

    private fun strengthPassTip(gender: PFRAGender, ageGroup: PFRAgeGroup, event: PFRAStrengthEvent): String {
        val minimum = when (gender to event) {
            PFRAGender.MALE to PFRAStrengthEvent.PUSH_UPS ->
                interpolated(30.0, 12.0, ageGroup).roundToInt()
            PFRAGender.FEMALE to PFRAStrengthEvent.PUSH_UPS ->
                interpolated(15.0, 3.0, ageGroup).roundToInt()
            PFRAGender.MALE to PFRAStrengthEvent.HAND_RELEASE_PUSH_UPS ->
                interpolated(27.0, 11.0, ageGroup).roundToInt()
            PFRAGender.FEMALE to PFRAStrengthEvent.HAND_RELEASE_PUSH_UPS ->
                interpolated(17.0, 1.0, ageGroup).roundToInt()
            else -> 0
        }
        return "Hit at least $minimum ${event.title.lowercase()} for 2.5 strength points."
    }

    private fun corePassTip(gender: PFRAGender, ageGroup: PFRAgeGroup, event: PFRACoreEvent): String =
        when (event) {
            PFRACoreEvent.FOREARM_PLANK -> {
                val minimum = interpolated(
                    if (gender == PFRAGender.MALE) 95.0 else 90.0,
                    if (gender == PFRAGender.MALE) 55.0 else 50.0,
                    ageGroup
                )
                "Hold forearm plank for at least ${formatPlankTime(minimum)} for 2.5 core points."
            }
            PFRACoreEvent.SIT_UPS, PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH -> {
                val minimum = when (gender to event) {
                    PFRAGender.MALE to PFRACoreEvent.SIT_UPS ->
                        interpolated(33.0, 17.0, ageGroup).roundToInt()
                    PFRAGender.FEMALE to PFRACoreEvent.SIT_UPS ->
                        interpolated(29.0, 6.0, ageGroup).roundToInt()
                    PFRAGender.MALE to PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH ->
                        interpolated(35.0, 19.0, ageGroup).roundToInt()
                    PFRAGender.FEMALE to PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH ->
                        interpolated(33.0, 17.0, ageGroup).roundToInt()
                    else -> 0
                }
                "Hit at least $minimum ${event.title.lowercase()} for 2.5 core points."
            }
        }

    // MARK: - Threshold tables (March 2026 PFRA charts, Air Force)

    private fun twoMileBest50(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 13 * 60 + 25.0 else 15 * 60 + 30.0

    private fun twoMileBest50Old(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 16 * 60 + 58.0 else 18 * 60 + 20.0

    private fun twoMileMin35(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 19 * 60 + 45.0 else 25 * 60 + 23.0

    private fun twoMileMin35Old(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 24 * 60.0 else 29 * 60 + 40.0

    private fun hamrMin35(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 42.0 else 21.0

    private fun hamrMin35Old(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 26.0 else 11.0

    private fun hamrMax50(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 87.0 else 58.0

    private fun hamrMax50Old(gender: PFRAGender): Double =
        if (gender == PFRAGender.MALE) 65.0 else 42.0

    // MARK: - Math helpers

    private fun interpolated(young: Double, old: Double, ageGroup: PFRAgeGroup): Double {
        val progress = ageGroup.rawValue.toDouble() / PFRAgeGroup.SIXTY_PLUS.rawValue.toDouble()
        return young + (old - young) * progress
    }

    private fun scoreHigherIsBetter(
        value: Double,
        minimum: Double,
        maximum: Double,
        maxPoints: Double,
        minPoints: Double
    ): Double {
        if (value < minimum) return 0.0
        if (maximum <= minimum) return if (value >= minimum) minPoints else 0.0
        if (value >= maximum) return maxPoints
        return minPoints + ((value - minimum) / (maximum - minimum)) * (maxPoints - minPoints)
    }

    private fun scoreLowerIsBetter(
        value: Double,
        best: Double,
        minimum: Double,
        maxPoints: Double,
        minPoints: Double
    ): Double {
        if (value > minimum) return 0.0
        if (minimum <= best) return if (value <= best) maxPoints else minPoints
        if (value <= best) return maxPoints
        return maxPoints - ((value - best) / (minimum - best)) * (maxPoints - minPoints)
    }

    fun formatRunTime(seconds: Double): String {
        val total = max(0, seconds.roundToInt())
        val minutes = total / 60
        val secs = total % 60
        return "%d:%02d".format(minutes, secs)
    }

    fun formatPlankTime(seconds: Double): String {
        val total = max(0, seconds.roundToInt())
        val minutes = total / 60
        val secs = total % 60
        return if (minutes > 0) "%d:%02d".format(minutes, secs) else "${secs}s"
    }

    fun parseRunTime(text: String): Double? {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return null
        trimmed.toDoubleOrNull()?.let { return it }
        val parts = trimmed.split(":")
        if (parts.size != 2) return null
        val minutes = parts[0].toDoubleOrNull() ?: return null
        val secs = parts[1].toDoubleOrNull() ?: return null
        return minutes * 60 + secs
    }

    fun parsePlankTime(text: String): Double? {
        parseRunTime(text)?.let { return it }
        val trimmed = text.trim().lowercase()
        if (trimmed.endsWith("s")) {
            return trimmed.dropLast(1).toDoubleOrNull()
        }
        return null
    }

    // MARK: - Goal planning (reverse lookup)

    fun cardioPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACardioEvent,
        value: Double
    ): Double = scoreCardio(gender, ageGroup, event, value).points

    fun strengthPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRAStrengthEvent,
        reps: Int
    ): Double = scoreStrength(gender, ageGroup, event, reps).points

    fun corePoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACoreEvent,
        value: Double
    ): Double = scoreCore(gender, ageGroup, event, value).points

    fun bodyPoints(heightInches: Double, waistInches: Double): Double =
        scoreWHtR(waistInches, heightInches).points

    fun performanceForCardioPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACardioEvent,
        targetPoints: Double
    ): Double? {
        return when (event) {
            PFRACardioEvent.TWO_MILE_RUN -> {
                val best = interpolated(twoMileBest50(gender), twoMileBest50Old(gender), ageGroup)
                val minimum = interpolated(twoMileMin35(gender), twoMileMin35Old(gender), ageGroup)
                if (cardioPoints(gender, ageGroup, event, best) < targetPoints) return null

                var low = best.roundToInt()
                var high = minimum.roundToInt()
                while (low < high) {
                    val mid = (low + high + 1) / 2
                    if (cardioPoints(gender, ageGroup, event, mid.toDouble()) >= targetPoints) {
                        low = mid
                    } else {
                        high = mid - 1
                    }
                }
                low.toDouble()
            }
            PFRACardioEvent.HAMR -> {
                var low = 0
                var high = 120
                while (low < high) {
                    val mid = (low + high) / 2
                    if (cardioPoints(gender, ageGroup, event, mid.toDouble()) >= targetPoints) {
                        high = mid
                    } else {
                        low = mid + 1
                    }
                }
                if (cardioPoints(gender, ageGroup, event, low.toDouble()) < targetPoints) null else low.toDouble()
            }
        }
    }

    fun waistInchesForWHtRPoints(heightInches: Double, targetPoints: Double): Double? {
        if (heightInches <= 0) return null

        var lowTenths = 1
        var highTenths = (heightInches * 0.59 * 10).toInt()
        if (highTenths <= lowTenths) return null

        while (lowTenths < highTenths) {
            val mid = (lowTenths + highTenths) / 2
            val waist = mid / 10.0
            if (bodyPoints(heightInches, waist) >= targetPoints) {
                highTenths = mid
            } else {
                lowTenths = mid + 1
            }
        }

        val waist = lowTenths / 10.0
        return if (bodyPoints(heightInches, waist) >= targetPoints) waist else null
    }

    fun performanceForStrengthPoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRAStrengthEvent,
        targetPoints: Double
    ): Double? {
        var low = 0
        var high = 120
        while (low < high) {
            val mid = (low + high) / 2
            if (strengthPoints(gender, ageGroup, event, mid) >= targetPoints) {
                high = mid
            } else {
                low = mid + 1
            }
        }
        return if (strengthPoints(gender, ageGroup, event, low) >= targetPoints) low.toDouble() else null
    }

    fun performanceForCorePoints(
        gender: PFRAGender,
        ageGroup: PFRAgeGroup,
        event: PFRACoreEvent,
        targetPoints: Double
    ): Double? {
        return when (event) {
            PFRACoreEvent.SIT_UPS, PFRACoreEvent.CROSS_LEG_REVERSE_CRUNCH -> {
                var low = 0
                var high = 120
                while (low < high) {
                    val mid = (low + high) / 2
                    if (corePoints(gender, ageGroup, event, mid.toDouble()) >= targetPoints) {
                        high = mid
                    } else {
                        low = mid + 1
                    }
                }
                if (corePoints(gender, ageGroup, event, low.toDouble()) >= targetPoints) low.toDouble() else null
            }
            PFRACoreEvent.FOREARM_PLANK -> {
                var low = 0
                var high = 300
                while (low < high) {
                    val mid = (low + high) / 2
                    if (corePoints(gender, ageGroup, event, mid.toDouble()) >= targetPoints) {
                        high = mid
                    } else {
                        low = mid + 1
                    }
                }
                if (corePoints(gender, ageGroup, event, low.toDouble()) >= targetPoints) low.toDouble() else null
            }
        }
    }
}
