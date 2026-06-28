import Foundation
import Testing
@testable import MyAFBase

struct NotificationDismissalStoreTests {

    @Test func dismissSingleNotification() {
        let key = "test.dismiss.single"
        UserDefaults.standard.removeObject(forKey: key)
        let store = NotificationDismissalStore(storageKey: key)
        #expect(!store.isDismissed(baseID: "keesler", notificationID: "n1"))

        store.dismiss(baseID: "keesler", notificationID: "n1")
        #expect(store.isDismissed(baseID: "keesler", notificationID: "n1"))
    }

    @Test func dismissAllNotifications() {
        let key = "test.dismiss.all"
        UserDefaults.standard.removeObject(forKey: key)
        let store = NotificationDismissalStore(storageKey: key)
        store.dismissAll(baseID: "keesler", notificationIDs: ["n1", "n2", "n3"])

        #expect(store.isDismissed(baseID: "keesler", notificationID: "n1"))
        #expect(store.isDismissed(baseID: "keesler", notificationID: "n2"))
        #expect(store.isDismissed(baseID: "keesler", notificationID: "n3"))
        #expect(!store.isDismissed(baseID: "keesler", notificationID: "n4"))
    }

    @Test func dismissalsAreScopedPerBase() {
        let key = "test.dismiss.perBase"
        UserDefaults.standard.removeObject(forKey: key)
        let store = NotificationDismissalStore(storageKey: key)
        store.dismiss(baseID: "keesler", notificationID: "n1")

        #expect(store.isDismissed(baseID: "keesler", notificationID: "n1"))
        #expect(!store.isDismissed(baseID: "eglin", notificationID: "n1"))
    }
}
