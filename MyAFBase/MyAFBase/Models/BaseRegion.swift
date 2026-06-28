import Foundation

enum BaseRegion: String, Codable, CaseIterable, Equatable {
    case conus
    case oconus

    var displayName: String {
        switch self {
        case .conus: return "CONUS"
        case .oconus: return "OCONUS"
        }
    }
}

enum BaseRegionFilter: String, CaseIterable, Identifiable {
    case all
    case conus
    case oconus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .conus: return "CONUS"
        case .oconus: return "OCONUS"
        }
    }

    func matches(_ region: BaseRegion) -> Bool {
        switch self {
        case .all: return true
        case .conus: return region == .conus
        case .oconus: return region == .oconus
        }
    }
}
