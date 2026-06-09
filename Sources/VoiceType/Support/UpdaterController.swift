import Foundation
import Sparkle

/// Thin wrapper around Sparkle's standard updater. Starting it schedules the
/// background appcast checks configured in Info.plist (`SUFeedURL`,
/// `SUScheduledCheckInterval`); every update is verified against `SUPublicEDKey`
/// before it can install, so an attacker can't ship a malicious build.
@MainActor
final class UpdaterController {
    private let controller: SPUStandardUpdaterController

    init() {
        // startingUpdater: true → begins scheduled checks immediately.
        controller = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
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
