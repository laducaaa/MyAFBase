import SwiftUI

struct EventDetailSheet: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(event.date.formatted(date: .long, time: .omitted), systemImage: "calendar")
                    if let timeRange = event.timeRangeText {
                        Label(timeRange, systemImage: "clock")
                    }
                }

                Section("Location") {
                    Text(event.location)
                    if let address = event.displayAddress {
                        Text(address)
                            .foregroundStyle(.secondary)
                    }
                    if let address = event.displayAddress {
                        Button {
                            MapsHelper.open(address: address)
                        } label: {
                            Label("Open in Maps", systemImage: "map")
                                .labelStyle(AppAccentIconLabelStyle())
                        }
                    }
                }

                Section("Details") {
                    Text(event.description)
                }
            }
            .navigationTitle(event.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
