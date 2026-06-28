import Foundation

struct NotificationItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let type: NotificationType
    let postedAt: Date
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var isActive: Bool {
        !isExpired
    }
}
