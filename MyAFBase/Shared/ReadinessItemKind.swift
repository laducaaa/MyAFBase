import Foundation

enum ReadinessItemKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case fitness
    case dental
    case eval
    case cac
    case clearance
    case pcsWindow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fitness: "PT test"
        case .dental: "Dental"
        case .eval: "EPR / OPB"
        case .cac: "CAC"
        case .clearance: "Clearance"
        case .pcsWindow: "PCS window"
        }
    }

    var systemImage: String {
        switch self {
        case .fitness: "figure.run"
        case .dental: "mouth.fill"
        case .eval: "doc.text.fill"
        case .cac: "person.crop.rectangle.fill"
        case .clearance: "lock.shield.fill"
        case .pcsWindow: "airplane.departure"
        }
    }

    /// Kinds safe to expose in Home Screen widgets (excludes CAC/clearance metadata).
    static let widgetKinds: [ReadinessItemKind] = [.fitness, .dental, .eval, .pcsWindow]
}
