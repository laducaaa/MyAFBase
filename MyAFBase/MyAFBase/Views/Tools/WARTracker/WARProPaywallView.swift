import RevenueCat
import SwiftUI

struct WARProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseService.self) private var purchaseService

    @State private var package: Package?
    @State private var isLoadingPackage = false
    @State private var packageErrorMessage: String?
    @State private var operation: Operation?
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private enum Operation: Equatable {
        case purchase
        case restore
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    hero
                    features
                    privacyNote
                }
                .padding(AppTheme.screenPadding)
                .padding(.bottom, 12)
            }
            .appScreenBackground()
            .navigationTitle("WAR Tracker Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .disabled(operation != nil)
                }
            }
            .safeAreaInset(edge: .bottom) {
                purchaseActions
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(operation != nil)
        .task {
            await loadPackage()
        }
        .alert(
            "Purchase Unavailable",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.badge.star")
                .font(.system(size: 52, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.brandSecondary)

            Text("Turn accomplishments into ready-to-use records")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Unlock WAR Tracker Pro once and keep it for the lifetime of the app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let package {
                Text("\(package.localizedPriceString) one-time purchase")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .appCardStyle()
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Included")
                .font(.headline)

            paywallFeature(
                systemImage: "square.and.pencil",
                title: "Fast accomplishment logging",
                detail: "Capture entries in the app or start from the quick-log widget and Siri."
            )
            paywallFeature(
                systemImage: "chart.bar.doc.horizontal",
                title: "Reports and exports",
                detail: "Build date-range summaries, copy formatted text, and export PDFs."
            )
            paywallFeature(
                systemImage: "flag.checkered",
                title: "Award tracking tools",
                detail: "Keep award deadlines and supporting accomplishments together."
            )
        }
        .appCardStyle()
    }

    private var privacyNote: some View {
        Label {
            Text("Your WAR entries remain on this device and are never sent to RevenueCat.")
                .font(.footnote)
        } icon: {
            Image(systemName: "lock.shield.fill")
        }
        .foregroundStyle(.secondary)
        .appCardStyle()
    }

    private var purchaseActions: some View {
        VStack(spacing: 10) {
            if isLoadingPackage && package == nil {
                ProgressView("Loading purchase options…")
                    .frame(maxWidth: .infinity)
            } else if let package {
                Button {
                    purchase(package)
                } label: {
                    HStack {
                        if operation == .purchase {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Unlock for \(package.localizedPriceString)")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .disabled(operation != nil)
            } else {
                VStack(spacing: 8) {
                    Text(packageErrorMessage ?? "Purchase options are unavailable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Try Again") {
                        Task { await loadPackage() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(operation != nil)
                }
            }

            Button {
                restore()
            } label: {
                HStack {
                    if operation == .restore {
                        ProgressView()
                    }
                    Text("Restore Purchases")
                }
            }
            .disabled(operation != nil)

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("One-time purchase. No subscription.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func paywallFeature(systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(systemImage: systemImage, tint: AppTheme.brandSecondary, size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadPackage() async {
        guard !isLoadingPackage else { return }
        isLoadingPackage = true
        packageErrorMessage = nil
        defer { isLoadingPackage = false }

        do {
            package = try await purchaseService.warProPackage()
        } catch {
            package = nil
            packageErrorMessage = error.localizedDescription
        }
    }

    private func purchase(_ package: Package) {
        Task {
            operation = .purchase
            statusMessage = nil
            defer { operation = nil }

            do {
                switch try await purchaseService.purchaseWARPro(package: package) {
                case .purchased:
                    statusMessage = "Purchase complete. WAR Tracker Pro is unlocked."
                case .cancelled:
                    break
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restore() {
        Task {
            operation = .restore
            statusMessage = nil
            defer { operation = nil }

            do {
                let restored = try await purchaseService.restorePurchases()
                if !restored {
                    statusMessage = "No previous WAR Tracker Pro purchase was found for this Apple ID."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct WARProLockedView: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.brandSecondary)

            Text("WAR Tracker Pro")
                .font(.title2.weight(.bold))

            Text("Unlock accomplishment logging, reports, exports, and award tracking with one lifetime purchase.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button(action: onUnlock) {
                Label("View Purchase Options", systemImage: "sparkles")
                    .frame(maxWidth: 240)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)

            Text("Any WAR data already on this device stays here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
        .navigationTitle("WAR Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }
}
