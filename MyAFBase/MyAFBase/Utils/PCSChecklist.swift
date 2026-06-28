import Foundation

struct PCSChecklistItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String?
}

enum PCSChecklistKind: String, CaseIterable, Identifiable {
    case inbound
    case outbound

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbound: "Inbound PCS"
        case .outbound: "Outbound PCS"
        }
    }

    var footer: String {
        switch self {
        case .inbound:
            "Track key in-processing steps for your arrival. Progress is saved on this device."
        case .outbound:
            "Track out-processing and move tasks before your next assignment."
        }
    }

    var systemImage: String {
        switch self {
        case .inbound: "checklist"
        case .outbound: "suitcase"
        }
    }
}

enum PCSChecklist {
    static func items(for kind: PCSChecklistKind) -> [PCSChecklistItem] {
        switch kind {
        case .inbound: inboundItems
        case .outbound: outboundItems
        }
    }

    private static let inboundItems: [PCSChecklistItem] = [
        PCSChecklistItem(id: "in-orders", title: "Obtain and review PCS orders", detail: "Keep digital and paper copies accessible."),
        PCSChecklistItem(id: "in-sponsor", title: "Contact your sponsor", detail: "Confirm reporting date, lodging, and arrival instructions."),
        PCSChecklistItem(id: "in-lodging", title: "Arrange temporary lodging", detail: "Book TLF or approved lodging if arriving before housing."),
        PCSChecklistItem(id: "in-report", title: "Report to unit / MPF", detail: "Complete in-processing within required timelines."),
        PCSChecklistItem(id: "in-deers", title: "Update DEERS and ID card", detail: "Visit MPF or RAPIDS if dependents or cards changed."),
        PCSChecklistItem(id: "in-finance", title: "Visit finance / RAO", detail: "Review pay, BAH, and travel voucher status."),
        PCSChecklistItem(id: "in-medical", title: "Enroll in medical and dental", detail: "Tricare enrollment and PCM assignment."),
        PCSChecklistItem(id: "in-housing", title: "Apply for housing or sign lease", detail: "On-base housing office or off-base lease."),
        PCSChecklistItem(id: "in-vehicle", title: "Register vehicle on installation", detail: "Base registration and required insurance proof."),
        PCSChecklistItem(id: "in-tmo", title: "Coordinate POV / HHG shipment", detail: "Schedule TMO pickup or delivery windows."),
        PCSChecklistItem(id: "in-schools", title: "Enroll children in school / CDC", detail: "If applicable, contact school liaison or CDC."),
        PCSChecklistItem(id: "in-address", title: "Update mailing address and agencies", detail: "USPS, bank, Tricare, and employer records.")
    ]

    private static let outboundItems: [PCSChecklistItem] = [
        PCSChecklistItem(id: "out-orders", title: "Receive and verify outbound orders", detail: "Confirm RNLTD, projected departure, and dependents."),
        PCSChecklistItem(id: "out-mpf", title: "Schedule MPF out-processing", detail: "DEERS updates, assignments, and personnel records."),
        PCSChecklistItem(id: "out-medical", title: "Complete medical and dental clearing", detail: "Records transfer and any required appointments."),
        PCSChecklistItem(id: "out-finance", title: "Finance clearing and final LES review", detail: "Final entitlements, travel vouchers, and advances."),
        PCSChecklistItem(id: "out-housing", title: "Schedule housing move-out inspection", detail: "On-base turn-in or lease termination off-base."),
        PCSChecklistItem(id: "out-cif", title: "Turn in issued equipment / CIF", detail: "Clear supply and equipment accounts."),
        PCSChecklistItem(id: "out-tmo", title: "Schedule TMO / HHG pickup", detail: "Weight tickets and shipment dates."),
        PCSChecklistItem(id: "out-utilities", title: "Cancel utilities and local services", detail: "Power, internet, gym, and other recurring services."),
        PCSChecklistItem(id: "out-gain-base", title: "Research your gaining installation", detail: "Switch bases in MyAFBase to preview your next assignment."),
        PCSChecklistItem(id: "out-pass", title: "Return passes and update gate access", detail: "Visitor passes, long-term decals, and vehicle registration.")
    ]
}
