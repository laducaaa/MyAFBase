import SwiftUI

struct NewcomerSectionDetailView: View {
    let section: NewcomerSection

    var body: some View {
        List {
            Section {
                Text(section.body)
                    .foregroundStyle(.primary)
            }

            if let links = section.links, !links.isEmpty {
                Section("Links") {
                    ForEach(links) { link in
                        if let url = normalizedURL(link.url) {
                            Link(destination: url) {
                                Label(link.title, systemImage: "link")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .tint(.primary)
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private func normalizedURL(_ string: String) -> URL? {
        if string.hasPrefix("http") {
            return URL(string: string)
        }
        return URL(string: "https://\(string)")
    }
}
