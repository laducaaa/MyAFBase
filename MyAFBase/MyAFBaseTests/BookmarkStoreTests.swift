import Foundation
import SwiftData
import Testing
@testable import MyAFBase

@MainActor
struct BookmarkStoreTests {

    @Test func toggleGateBookmark() throws {
        let container = try makeContainer()
        let store = BookmarkStore(modelContext: container.mainContext)

        #expect(!store.isBookmarked(baseID: "keesler", itemID: "gate-1", itemType: .gate))

        store.toggleGate(baseID: "keesler", gateID: "gate-1")
        #expect(store.isBookmarked(baseID: "keesler", itemID: "gate-1", itemType: .gate))

        store.toggleGate(baseID: "keesler", gateID: "gate-1")
        #expect(!store.isBookmarked(baseID: "keesler", itemID: "gate-1", itemType: .gate))
    }

    @Test func bookmarkedResourcesFilteredByBase() throws {
        let container = try makeContainer()
        let store = BookmarkStore(modelContext: container.mainContext)

        store.toggleResource(baseID: "keesler", resourceID: "res-1")
        store.toggleResource(baseID: "eglin", resourceID: "res-2")

        let keeslerBase = sampleBase(id: "keesler", resourceIDs: ["res-1", "res-3"])
        let keeslerResources = store.bookmarkedResources(for: keeslerBase)

        #expect(keeslerResources.count == 1)
        #expect(keeslerResources.first?.id == "res-1")
    }

    @Test func clearAllBookmarks() throws {
        let container = try makeContainer()
        let store = BookmarkStore(modelContext: container.mainContext)

        store.toggleGate(baseID: "keesler", gateID: "gate-1")
        store.toggleResource(baseID: "keesler", resourceID: "res-1")
        #expect(store.allBookmarks().count == 2)

        store.clearAllBookmarks()
        #expect(store.allBookmarks().isEmpty)
    }

    @Test func toggleEventBookmark() throws {
        let container = try makeContainer()
        let store = BookmarkStore(modelContext: container.mainContext)

        store.toggleEvent(baseID: "keesler", eventID: "evt-1")
        #expect(store.isBookmarked(baseID: "keesler", itemID: "evt-1", itemType: .event))

        store.toggleEvent(baseID: "keesler", eventID: "evt-1")
        #expect(!store.isBookmarked(baseID: "keesler", itemID: "evt-1", itemType: .event))
    }

    @Test func resolvedSavedItemsSortByMostRecent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let store = BookmarkStore(modelContext: context)

        let older = Bookmark(baseID: "keesler", itemID: "gate-1", itemType: BookmarkItemType.gate.rawValue, createdAt: Date(timeIntervalSince1970: 100))
        let newer = Bookmark(baseID: "keesler", itemID: "res-1", itemType: BookmarkItemType.resource.rawValue, createdAt: Date(timeIntervalSince1970: 200))
        context.insert(older)
        context.insert(newer)
        try context.save()

        let base = sampleBase(id: "keesler", resourceIDs: ["res-1"], gateIDs: ["gate-1"])
        let items = store.resolvedSavedItems(for: base, category: .all)

        #expect(items.count == 2)
        #expect(items.first?.resource?.id == "res-1")
    }

    @Test func toggleUpdatesObservationToken() throws {
        let container = try makeContainer()
        let store = BookmarkStore(modelContext: container.mainContext)

        #expect(store.changeToken == 0)

        store.toggleGate(baseID: "keesler", gateID: "gate-1")
        #expect(store.changeToken == 1)
        #expect(store.isBookmarked(baseID: "keesler", itemID: "gate-1", itemType: .gate))

        store.toggleGate(baseID: "keesler", gateID: "gate-1")
        #expect(store.changeToken == 2)
        #expect(!store.isBookmarked(baseID: "keesler", itemID: "gate-1", itemType: .gate))
    }

    @Test func resolvedSavedItemsFilterByCategory() throws {
        let container = try makeContainer()
        let store = BookmarkStore(modelContext: container.mainContext)

        store.toggleGate(baseID: "keesler", gateID: "gate-1")
        store.toggleResource(baseID: "keesler", resourceID: "res-1")

        let base = sampleBase(id: "keesler", resourceIDs: ["res-1"], gateIDs: ["gate-1"])
        let gates = store.resolvedSavedItems(for: base, category: .gates)

        #expect(gates.count == 1)
        #expect(gates.first?.gate?.id == "gate-1")
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Bookmark.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func sampleBase(id: String, resourceIDs: [String], gateIDs: [String] = []) -> Base {
        Base(
            id: id,
            name: "Test Base",
            fullName: "Test Base Full",
            location: "Test",
            description: "Test",
            wing: "TW",
            latitude: 0,
            longitude: 0,
            dataUpdatedAt: nil,
            currentNotifications: [],
            emergencyNumbers: [],
            gates: gateIDs.map {
                Gate(
                    id: $0,
                    name: $0,
                    status: .open,
                    hours: "24/7",
                    notes: nil,
                    traffic: .low,
                    address: nil,
                    latitude: nil,
                    longitude: nil
                )
            },
            resources: resourceIDs.map {
                Resource(
                    id: $0,
                    slug: nil,
                    name: $0,
                    category: .services,
                    description: nil,
                    hours: nil,
                    address: nil,
                    phone: nil,
                    url: nil,
                    building: nil,
                    type: .text,
                    value: ""
                )
            },
            events: [],
            newcomers: NewcomersInfo(sections: [])
        )
    }
}
