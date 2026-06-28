import AppIntents
import Foundation

struct ViewGateIntent: AppIntent {
    static var title: LocalizedStringResource = "View Gate"
    static var description = IntentDescription("Opens gate details in MyAFBase.")
    static var openAppWhenRun = true

    @Parameter(title: "Gate")
    var gateName: String

    @Parameter(title: "Base")
    var base: BaseEntity

    init() {
        self.gateName = ""
        self.base = BaseEntity(id: "", name: "", location: "")
    }

    init(gateName: String, base: BaseEntity) {
        self.gateName = gateName
        self.base = base
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct BookmarkResourceIntent: AppIntent {
    static var title: LocalizedStringResource = "Bookmark Resource"
    static var description = IntentDescription("Bookmarks a base resource in MyAFBase.")
    static var openAppWhenRun = false

    @Parameter(title: "Resource")
    var resourceName: String

    @Parameter(title: "Base")
    var base: BaseEntity

    init() {
        self.resourceName = ""
        self.base = BaseEntity(id: "", name: "", location: "")
    }

    init(resourceName: String, base: BaseEntity) {
        self.resourceName = resourceName
        self.base = base
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct ViewReadinessIntent: AppIntent {
    static var title: LocalizedStringResource = "View Readiness"
    static var description = IntentDescription("Opens readiness tracking in MyAFBase.")
    static var openAppWhenRun = true

    @Parameter(title: "Base")
    var base: BaseEntity

    init() {
        self.base = BaseEntity(id: "", name: "", location: "")
    }

    init(base: BaseEntity) {
        self.base = base
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}
