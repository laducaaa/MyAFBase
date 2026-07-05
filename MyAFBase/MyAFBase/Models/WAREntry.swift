import Foundation
import SwiftData

/// A single logged accomplishment. Stored on-device only (see
/// `ModelContainerFactory`) — WAR content is often sensitive, so it never
/// syncs through iCloud in v1.
@Model
final class WAREntry {
    var id: UUID = UUID()
    var baseID: String = ""
    var date: Date = Date()
    var text: String = ""
    var categoryRaw: String = WARCategory.job.rawValue
    var performanceFactorRaw: String?
    var tags: [String] = []
    var impact: String?
    var beneficiary: String?
    var hours: Double?
    var memberTypeRaw: String = WARMemberType.enlisted.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        baseID: String,
        date: Date = Date(),
        text: String,
        category: WARCategory = .job,
        performanceFactor: WARPerformanceFactor? = nil,
        tags: [String] = [],
        impact: String? = nil,
        beneficiary: String? = nil,
        hours: Double? = nil,
        memberType: WARMemberType = .enlisted,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.baseID = baseID
        self.date = date
        self.text = text
        self.categoryRaw = category.rawValue
        self.performanceFactorRaw = performanceFactor?.rawValue
        self.tags = tags
        self.impact = impact
        self.beneficiary = beneficiary
        self.hours = hours
        self.memberTypeRaw = memberType.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var category: WARCategory {
        get { WARCategory(rawValue: categoryRaw) ?? .job }
        set { categoryRaw = newValue.rawValue }
    }

    var performanceFactor: WARPerformanceFactor? {
        get { performanceFactorRaw.flatMap(WARPerformanceFactor.init(rawValue:)) }
        set { performanceFactorRaw = newValue?.rawValue }
    }

    var memberType: WARMemberType {
        get { WARMemberType(rawValue: memberTypeRaw) ?? .enlisted }
        set { memberTypeRaw = newValue.rawValue }
    }
}
