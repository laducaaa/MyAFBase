package com.ryanladuca.myafbase.domain.model

enum class AssignmentSegment(val raw: String, val title: String) {
    INBOUND("inbound", "In Processing"),
    STATIONED("stationed", "Stationed"),
    OUTBOUND("outbound", "Out Processing");

    companion object {
        fun fromRaw(value: String?): AssignmentSegment =
            entries.firstOrNull { it.raw == value } ?: STATIONED
    }
}

data class AssignmentProfile(
    val baseId: String = "",
    val phase: AssignmentSegment = AssignmentSegment.STATIONED,
    val reportDateMillis: Long? = null,
    val pcsDateMillis: Long? = null,
    val updatedAtMillis: Long = System.currentTimeMillis()
)

data class ReadinessTracker(
    val baseId: String = "",
    val fitnessTestDueMillis: Long? = null,
    val dentalDueMillis: Long? = null,
    val evalCloseoutDueMillis: Long? = null,
    val pcsWindowStartMillis: Long? = null,
    val pcsWindowEndMillis: Long? = null,
    val cacExpirationMillis: Long? = null,
    val clearanceRenewalMillis: Long? = null,
    val updatedAtMillis: Long = System.currentTimeMillis()
)

data class ReminderItem(
    val id: String,
    val title: String,
    val dueMillis: Long,
    val category: String
)

enum class HomeToolId(val id: String, val title: String, val subtitle: String) {
    PFRA_SCORE("pfra-score", "PFRA Score", "Estimate your fitness score"),
    PFRA_GOAL("pfra-goal", "PFRA Goals", "Plan what you need to hit"),
    AFI_SEARCH("afi-search", "Essential AFI Search", "Search essential AFI guidance offline"),
    WAR_TRACKER("war-tracker", "WAR Tracker", "Log accomplishments for awards and EPB/OPB"),
    LEAVE_PLANNER("leave-planner", "Leave Planner", "Upcoming leave & PCS planning"),
    PAY_CALENDAR("pay-calendar", "Pay Calendar", "Mid-month, month-end & special pays")
}
