import Foundation
import Sparkle

/// Thin wrapper around Sparkle's standard updater. Starting it schedules the
/// background appcast checks configured in Info.plist (`SUFeedURL`,
/// `SUScheduledCheckInterval`); every update is verified against `SUPublicEDKey`
/// before it can install, so an attacker can't ship a malicious build.
///
/// Also acts as the updater delegate so the app knows when an update is
/// pending: dismissing Sparkle's dialog otherwise leaves no way back to it
/// until the next scheduled check. The sidebar's "Update available" row hangs
/// off `onUpdateAvailabilityChange`.
@MainActor
final class UpdaterController: NSObject {
    private var controller: SPUStandardUpdaterController!

    /// Fires when Sparkle learns whether an update is pending — `true` on
    /// finding a valid update, `false` when a check comes back clean.
    var onUpdateAvailabilityChange: (@MainActor (Bool) -> Void)?

    override init() {
        super.init()
        // startingUpdater: true → begins scheduled checks immediately.
        controller = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }

    /// User-initiated check. Shows Sparkle's UI (no update / update available).
    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }

    var canCheckForUpdates: Bool {
        controller.updater.canCheckForUpdates
    }

    /// Whether Sparkle checks on its own schedule. Mirrors the user's toggle.
    var automaticallyChecks: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }
}

extension UpdaterController: SPUUpdaterDelegate {
    // Sparkle calls its delegate on the main thread; the methods are declared
    // nonisolated only because the protocol itself is.

    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        MainActor.assumeIsolated {
            onUpdateAvailabilityChange?(true)
        }
    }

    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        MainActor.assumeIsolated {
            onUpdateAvailabilityChange?(false)
        }
    }
}
