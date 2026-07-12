package com.ryanladuca.myafbase.data.prefs

import android.content.Context
import android.content.SharedPreferences
import com.ryanladuca.myafbase.domain.logic.PFRACardioEvent
import com.ryanladuca.myafbase.domain.logic.PFRACoreEvent
import com.ryanladuca.myafbase.domain.logic.PFRAGender
import com.ryanladuca.myafbase.domain.logic.PFRAStrengthEvent
import com.ryanladuca.myafbase.domain.logic.PFRATargetTier
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

data class PFRAProfile(
    val gender: PFRAGender = PFRAGender.MALE,
    val age: Int = 28,
    val heightFeet: Int = 5,
    val heightInches: Int = 10,
    val waistTenths: Int = 340,
    val cardioEvent: PFRACardioEvent = PFRACardioEvent.TWO_MILE_RUN,
    val runMinutes: Int = 15,
    val runSeconds: Int = 0,
    val hamrShuttles: Int = 60,
    val strengthEvent: PFRAStrengthEvent = PFRAStrengthEvent.PUSH_UPS,
    val strengthReps: Int = 40,
    val coreEvent: PFRACoreEvent = PFRACoreEvent.SIT_UPS,
    val coreReps: Int = 45,
    val plankMinutes: Int = 2,
    val plankSeconds: Int = 0,
    val targetTier: PFRATargetTier = PFRATargetTier.SATISFACTORY
) {
    val heightTotalInches: Double get() = (heightFeet * 12 + heightInches).toDouble()
    val waistInches: Double get() = waistTenths / 10.0
    val cardioValue: Double
        get() = when (cardioEvent) {
            PFRACardioEvent.TWO_MILE_RUN -> (runMinutes * 60 + runSeconds).toDouble()
            PFRACardioEvent.HAMR -> hamrShuttles.toDouble()
        }
    val coreValue: Double
        get() = when (coreEvent) {
            PFRACoreEvent.FOREARM_PLANK -> (plankMinutes * 60 + plankSeconds).toDouble()
            else -> coreReps.toDouble()
        }
}

class PFRAProfileStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("pfra_profile", Context.MODE_PRIVATE)

    private val _profile = MutableStateFlow(load())
    val profile: StateFlow<PFRAProfile> = _profile.asStateFlow()

    fun update(transform: (PFRAProfile) -> PFRAProfile) {
        val next = transform(_profile.value)
        _profile.value = next
        save(next)
    }

    private fun load(): PFRAProfile = PFRAProfile(
        gender = runCatching {
            PFRAGender.valueOf(prefs.getString("gender", PFRAGender.MALE.name)!!)
        }.getOrDefault(PFRAGender.MALE),
        age = prefs.getInt("age", 28),
        heightFeet = prefs.getInt("heightFeet", 5),
        heightInches = prefs.getInt("heightInches", 10),
        waistTenths = prefs.getInt("waistTenths", 340),
        cardioEvent = runCatching {
            PFRACardioEvent.valueOf(prefs.getString("cardioEvent", PFRACardioEvent.TWO_MILE_RUN.name)!!)
        }.getOrDefault(PFRACardioEvent.TWO_MILE_RUN),
        runMinutes = prefs.getInt("runMinutes", 15),
        runSeconds = prefs.getInt("runSeconds", 0),
        hamrShuttles = prefs.getInt("hamrShuttles", 60),
        strengthEvent = runCatching {
            PFRAStrengthEvent.valueOf(prefs.getString("strengthEvent", PFRAStrengthEvent.PUSH_UPS.name)!!)
        }.getOrDefault(PFRAStrengthEvent.PUSH_UPS),
        strengthReps = prefs.getInt("strengthReps", 40),
        coreEvent = runCatching {
            PFRACoreEvent.valueOf(prefs.getString("coreEvent", PFRACoreEvent.SIT_UPS.name)!!)
        }.getOrDefault(PFRACoreEvent.SIT_UPS),
        coreReps = prefs.getInt("coreReps", 45),
        plankMinutes = prefs.getInt("plankMinutes", 2),
        plankSeconds = prefs.getInt("plankSeconds", 0),
        targetTier = runCatching {
            PFRATargetTier.valueOf(prefs.getString("targetTier", PFRATargetTier.SATISFACTORY.name)!!)
        }.getOrDefault(PFRATargetTier.SATISFACTORY)
    )

    private fun save(p: PFRAProfile) {
        prefs.edit()
            .putString("gender", p.gender.name)
            .putInt("age", p.age)
            .putInt("heightFeet", p.heightFeet)
            .putInt("heightInches", p.heightInches)
            .putInt("waistTenths", p.waistTenths)
            .putString("cardioEvent", p.cardioEvent.name)
            .putInt("runMinutes", p.runMinutes)
            .putInt("runSeconds", p.runSeconds)
            .putInt("hamrShuttles", p.hamrShuttles)
            .putString("strengthEvent", p.strengthEvent.name)
            .putInt("strengthReps", p.strengthReps)
            .putString("coreEvent", p.coreEvent.name)
            .putInt("coreReps", p.coreReps)
            .putInt("plankMinutes", p.plankMinutes)
            .putInt("plankSeconds", p.plankSeconds)
            .putString("targetTier", p.targetTier.name)
            .apply()
    }
}
