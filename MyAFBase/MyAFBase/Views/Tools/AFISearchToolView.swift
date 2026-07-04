import SwiftUI

/// Standalone Essential AFI search tool — reachable from Home → Tools.
struct AFISearchToolView: View {
    var body: some View {
        ScrollView {
            AFISearchView()
                .padding()
        }
        .appScreenBackground()
        .navigationTitle("Essential AFI Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AFISearchToolView()
    }
    .environment(AFISearchService())
}
#endif
