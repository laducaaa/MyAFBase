import SwiftUI
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([
        Bookmark.self,
        ReadinessTracker.self,
        ChecklistCompletion.self,
        AssignmentProfile.self,
        WAREntry.self,
        WARAwardDeadline.self,
    ])

    private static var isPreviewRuntime: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }

    static func make() -> ModelContainer? {
        if isPreviewRuntime {
            return previewContainer()
        }

        #if targetEnvironment(simulator)
        return localContainer()
        #else
        if let cloudContainer = cloudContainer() {
            return cloudContainer
        }
        return localContainer()
        #endif
    }

    static func preview() -> ModelContainer {
        if let container = previewContainer() {
            return container
        }
        if let container = localContainer(inMemory: true) {
            return container
        }
        fatalError("Failed to create preview ModelContainer")
    }

    private static func previewContainer() -> ModelContainer? {
        localContainer(inMemory: true)
    }

    private static func cloudContainer() -> ModelContainer? {
        // Readiness dates (CAC, clearance, etc.) and WAR entries stay on-device
        // only — not synced to iCloud. WAR content is often sensitive, so it
        // never leaves the device in v1 even if iCloud sync is enabled for
        // other data.
        let readinessConfig = ModelConfiguration(
            "LocalReadiness",
            schema: Schema([ReadinessTracker.self, WAREntry.self, WARAwardDeadline.self]),
            cloudKitDatabase: .none
        )
        let cloudConfig = ModelConfiguration(
            "CloudShared",
            schema: Schema([Bookmark.self, ChecklistCompletion.self, AssignmentProfile.self]),
            cloudKitDatabase: .automatic
        )
        return try? ModelContainer(
            for: schema,
            configurations: [readinessConfig, cloudConfig]
        )
    }

    private static func localContainer(inMemory: Bool = false) -> ModelContainer? {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try? ModelContainer(for: schema, configurations: [configuration])
    }
}

@MainActor
struct AppStores {
    let bookmarkStore: BookmarkStore
    let readinessTrackerStore: ReadinessTrackerStore
    let checklistStore: ChecklistStore
    let assignmentProfileStore: AssignmentProfileStore
    let warTrackerStore: WARTrackerStore

    init(modelContext: ModelContext) {
        bookmarkStore = BookmarkStore(modelContext: modelContext)
        readinessTrackerStore = ReadinessTrackerStore(modelContext: modelContext)
        checklistStore = ChecklistStore(modelContext: modelContext)
        assignmentProfileStore = AssignmentProfileStore(modelContext: modelContext)
        warTrackerStore = WARTrackerStore(modelContext: modelContext)
    }

    init(
        bookmarkStore: BookmarkStore,
        readinessTrackerStore: ReadinessTrackerStore,
        checklistStore: ChecklistStore,
        assignmentProfileStore: AssignmentProfileStore,
        warTrackerStore: WARTrackerStore
    ) {
        self.bookmarkStore = bookmarkStore
        self.readinessTrackerStore = readinessTrackerStore
        self.checklistStore = checklistStore
        self.assignmentProfileStore = assignmentProfileStore
        self.warTrackerStore = warTrackerStore
    }
}

struct DataStoreErrorView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Unable to Start", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text("MyAFBase could not open its local data store. Try force-quitting and reopening the app. If the problem continues, reinstall the app.")
        }
        .padding()
    }
}

struct BaseLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.accent)

            Text("Loading installation...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
    }
}
