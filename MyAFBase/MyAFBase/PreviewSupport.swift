#if DEBUG
import SwiftData
import SwiftUI

@MainActor
enum PreviewSupport {
    private static var cachedModelContainer: ModelContainer?
    private static var cachedStores: AppStores?

    static var modelContainer: ModelContainer {
        if let cachedModelContainer {
            return cachedModelContainer
        }
        let container = ModelContainerFactory.preview()
        cachedModelContainer = container
        return container
    }

    static func makeAppState() -> AppState {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        return AppState()
    }

    static var stores: AppStores {
        if let cachedStores {
            return cachedStores
        }
        let stores = AppStores(modelContext: ModelContext(modelContainer))
        cachedStores = stores
        return stores
    }
}

struct ContentViewPreviewHost: View {
    @State private var appState = PreviewSupport.makeAppState()
    @State private var purchaseService = PurchaseService(
        hasWARPro: true,
        hasLoadedCustomerInfo: true
    )

    var body: some View {
        ContentView(stores: PreviewSupport.stores)
            .environment(appState)
            .environment(purchaseService)
            .modelContainer(PreviewSupport.modelContainer)
            .task {
                if appState.currentBase == nil {
                    await appState.selectBase(id: "keesler")
                }
            }
    }
}
#endif
