package com.ryanladuca.myafbase.domain.logic

data class PCSChecklistItem(
    val id: String,
    val title: String,
    val detail: String?
)

enum class PCSChecklistKind(val raw: String, val title: String, val footer: String) {
    INBOUND(
        "inbound",
        "Inbound PCS",
        "Track key in-processing steps for your arrival. Progress is saved on this device."
    ),
    OUTBOUND(
        "outbound",
        "Outbound PCS",
        "Track out-processing and move tasks before your next assignment."
    )
}

object PCSChecklist {
    fun items(forKind: PCSChecklistKind): List<PCSChecklistItem> = when (forKind) {
        PCSChecklistKind.INBOUND -> inboundItems
        PCSChecklistKind.OUTBOUND -> outboundItems
    }

    private val inboundItems = listOf(
        PCSChecklistItem("in-orders", "Obtain and review PCS orders", "Keep digital and paper copies accessible."),
        PCSChecklistItem("in-sponsor", "Contact your sponsor", "Confirm reporting date, lodging, and arrival instructions."),
        PCSChecklistItem("in-lodging", "Arrange temporary lodging", "Book TLF or approved lodging if arriving before housing."),
        PCSChecklistItem("in-report", "Report to unit / MPF", "Complete in-processing within required timelines."),
        PCSChecklistItem("in-deers", "Update DEERS and ID card", "Visit MPF or RAPIDS if dependents or cards changed."),
        PCSChecklistItem("in-finance", "Visit finance / RAO", "Review pay, BAH, and travel voucher status."),
        PCSChecklistItem("in-medical", "Enroll in medical and dental", "Tricare enrollment and PCM assignment."),
        PCSChecklistItem("in-housing", "Apply for housing or sign lease", "On-base housing office or off-base lease."),
        PCSChecklistItem("in-vehicle", "Register vehicle on installation", "Base registration and required insurance proof."),
        PCSChecklistItem("in-tmo", "Coordinate POV / HHG shipment", "Schedule TMO pickup or delivery windows."),
        PCSChecklistItem("in-schools", "Enroll children in school / CDC", "If applicable, contact school liaison or CDC."),
        PCSChecklistItem("in-address", "Update mailing address and agencies", "USPS, bank, Tricare, and employer records.")
    )

    private val outboundItems = listOf(
        PCSChecklistItem("out-orders", "Receive and verify outbound orders", "Confirm RNLTD, projected departure, and dependents."),
        PCSChecklistItem("out-mpf", "Schedule MPF out-processing", "DEERS updates, assignments, and personnel records."),
        PCSChecklistItem("out-medical", "Complete medical and dental clearing", "Records transfer and any required appointments."),
        PCSChecklistItem("out-finance", "Finance clearing and final LES review", "Final entitlements, travel vouchers, and advances."),
        PCSChecklistItem("out-housing", "Schedule housing move-out inspection", "On-base turn-in or lease termination off-base."),
        PCSChecklistItem("out-cif", "Turn in issued equipment / CIF", "Clear supply and equipment accounts."),
        PCSChecklistItem("out-tmo", "Schedule TMO / HHG pickup", "Weight tickets and shipment dates."),
        PCSChecklistItem("out-utilities", "Cancel utilities and local services", "Power, internet, gym, and other recurring services."),
        PCSChecklistItem("out-gain-base", "Research your gaining installation", "Switch bases in MyAFBase to preview your next assignment."),
        PCSChecklistItem("out-pass", "Return passes and update gate access", "Visitor passes, long-term decals, and vehicle registration.")
    )
}
