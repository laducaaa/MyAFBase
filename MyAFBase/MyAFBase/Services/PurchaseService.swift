import Foundation
import Observation
import RevenueCat

@MainActor
enum RevenueCatConfiguration {
    static let apiKey = "appl_CVbUWFxhtpgbfjgpRphyooMhhWr"
    static let warProEntitlementIdentifier = "war_pro"
    static let warProOfferingIdentifier = "war_pro"

    static func configure() {
        guard !Purchases.isConfigured else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: apiKey)
    }
}

enum PurchaseOutcome {
    case purchased
    case cancelled
}

enum PurchaseServiceError: LocalizedError {
    case warProOfferingUnavailable
    case lifetimePackageUnavailable
    case entitlementNotGranted

    var errorDescription: String? {
        switch self {
        case .warProOfferingUnavailable:
            "WAR Tracker Pro is not available right now. Please try again later."
        case .lifetimePackageUnavailable:
            "The WAR Tracker Pro lifetime purchase could not be loaded. Please try again later."
        case .entitlementNotGranted:
            "The purchase completed, but access has not updated yet. Try Restore Purchases."
        }
    }
}

@MainActor
@Observable
final class PurchaseService {
    private(set) var hasWARPro: Bool
    private(set) var hasLoadedCustomerInfo: Bool

    private var isObservingCustomerInfo = false

    init(hasWARPro: Bool = false, hasLoadedCustomerInfo: Bool = false) {
        self.hasWARPro = hasWARPro
        self.hasLoadedCustomerInfo = hasLoadedCustomerInfo
    }

    func observeCustomerInfo() async {
        guard !isObservingCustomerInfo else { return }
        isObservingCustomerInfo = true
        defer { isObservingCustomerInfo = false }

        await refreshCustomerInfo()

        for await customerInfo in Purchases.shared.customerInfoStream {
            guard !Task.isCancelled else { break }
            apply(customerInfo)
        }
    }

    func refreshCustomerInfo() async {
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            // RevenueCat returns cached CustomerInfo when available. If there is
            // no cache and the refresh fails, keep the feature gated.
            hasLoadedCustomerInfo = true
            #if DEBUG
            print("RevenueCat customer info refresh failed: \(error)")
            #endif
        }
    }

    func warProPackage() async throws -> Package {
        let offerings = try await Purchases.shared.offerings()

        guard let current = offerings.current,
              current.identifier == RevenueCatConfiguration.warProOfferingIdentifier else {
            throw PurchaseServiceError.warProOfferingUnavailable
        }

        guard let lifetimePackage = current.lifetime else {
            throw PurchaseServiceError.lifetimePackageUnavailable
        }

        return lifetimePackage
    }

    func purchaseWARPro(package: Package) async throws -> PurchaseOutcome {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                return .cancelled
            }

            apply(result.customerInfo)
            guard hasWARPro else {
                throw PurchaseServiceError.entitlementNotGranted
            }
            return .purchased
        } catch {
            if (error as NSError).code == ErrorCode.purchaseCancelledError.rawValue {
                return .cancelled
            }
            throw error
        }
    }

    @discardableResult
    func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        apply(customerInfo)
        return hasWARPro
    }

    private func apply(_ customerInfo: CustomerInfo) {
        hasWARPro = customerInfo.entitlements.active[
            RevenueCatConfiguration.warProEntitlementIdentifier
        ] != nil
        hasLoadedCustomerInfo = true
    }
}
