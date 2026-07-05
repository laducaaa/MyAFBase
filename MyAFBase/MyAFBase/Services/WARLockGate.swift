import Foundation
import LocalAuthentication
import SwiftUI

/// Optional Face ID / passcode gate on the WAR Tracker section. Off by
/// default (`WARSettingsStore.lockEnabled`); when enabled, the tracker
/// re-locks whenever the app moves to the background.
@MainActor
@Observable
final class WARLockState {
    private(set) var isUnlocked = !WARSettingsStore.lockEnabled
    private(set) var lastAttemptFailed = false

    func attemptUnlock() async {
        guard WARSettingsStore.lockEnabled else {
            isUnlocked = true
            return
        }
        guard !isUnlocked else { return }

        let success = await WARLockService.authenticate()
        isUnlocked = success
        lastAttemptFailed = !success
    }

    func lockIfNeeded() {
        guard WARSettingsStore.lockEnabled else { return }
        isUnlocked = false
        lastAttemptFailed = false
    }
}

enum WARLockService {
    @MainActor
    static func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No passcode/biometrics configured on this device — don't lock
            // the user out of their own data over a device limitation.
            return true
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock WAR Tracker"
            )
        } catch {
            return false
        }
    }
}

struct WARLockedView: View {
    let onUnlock: () async -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accent)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

            Text("WAR Tracker Locked")
                .font(.title3.weight(.semibold))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            Text("Face ID or passcode is required to view your accomplishment log.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Button {
                Task { await onUnlock() }
            } label: {
                Label("Unlock", systemImage: "faceid")
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
        .navigationTitle("WAR Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(WARMotion.spring) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}
