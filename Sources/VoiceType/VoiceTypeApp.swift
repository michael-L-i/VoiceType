import SwiftUI
import AppKit
import VoiceTypeKit

/// Menu-bar entry point. VoiceType has no dock icon and no main window — it is a
/// background agent you summon with a hotkey.
@main
struct VoiceTypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(coordinator: appDelegate.coordinator)
        } label: {
            Image(systemName: appDelegate.coordinator.menuBarSymbol)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = DictationCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar agent: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)
        coordinator.start()

        // First-run: nudge through the required grants. The settings/onboarding
        // milestone replaces this with a proper guided flow.
        if !coordinator.permissionsGranted {
            Task { await coordinator.requestAllPermissions() }
        }
        Log.app.info("VoiceType launched")
    }
}
