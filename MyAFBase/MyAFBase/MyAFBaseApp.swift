import SwiftUI
import SwiftData

@main
struct MyAFBaseApp: App {
    @State private var appState = AppState()
    @State private var purchaseService = PurchaseService()
    private let modelContainer = ModelContainerFactory.make()

    init() {
        RevenueCatConfiguration.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let modelContainer {
                    ContentView()
                        .modelContainer(modelContainer)
                } else {
                    DataStoreErrorView()
                }
            }
            .environment(appState)
            .environment(purchaseService)
            .task {
                await purchaseService.observeCustomerInfo()
            }
        }
    }
}
