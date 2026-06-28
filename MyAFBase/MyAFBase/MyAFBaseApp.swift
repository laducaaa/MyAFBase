import SwiftUI
import SwiftData

@main
struct MyAFBaseApp: App {
    @State private var appState = AppState()
    private let modelContainer = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                ContentView()
                    .environment(appState)
                    .modelContainer(modelContainer)
            } else {
                DataStoreErrorView()
            }
        }
    }
}
