import SwiftUI
import AppKit
import VoiceTypeKit

/// Menu-bar entry point. VoiceType has no dock icon and no main window — it is a
/// background agent you summon with a hotkey. The Settings and Onboarding scenes
/// are summoned on demand (from the menu, or auto-shown on first run).
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

        // Preferences. macOS gives this the standard ⌘, and window chrome.
        Settings {
            SettingsView(coordinator: appDelegate.coordinator)
        }

        // First-run / re-openable permissions walkthrough. Opening is driven by
        // `coordinator.wantsOnboarding`, which the window bridge observes so both
        // the AppDelegate (first launch) and the menu can request it.
        Window("Welcome to VoiceType", id: WindowID.onboarding) {
            OnboardingView(coordinator: appDelegate.coordinator) {
                appDelegate.coordinator.wantsOnboarding = false
                dismissWindow(WindowID.onboarding)
            }
            .background(OnboardingWindowBridge(coordinator: appDelegate.coordinator))
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
    }
}

/// Stable identifiers for the on-demand windows.
enum WindowID {
    static let onboarding = "onboarding"
}

/// Bridges `coordinator.wantsOnboarding` to SwiftUI's `openWindow`, which is only
/// reachable from a `View` environment. Lives invisibly inside the onboarding
/// scene so it is always mounted.
private struct OnboardingWindowBridge: View {
    @Bindable var coordinator: DictationCoordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .onChange(of: coordinator.wantsOnboarding) { _, wants in
                if wants {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: WindowID.onboarding)
                }
            }
            .onAppear {
                if coordinator.wantsOnboarding {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: WindowID.onboarding)
                }
            }
    }
}

/// Close a SwiftUI-managed window by id (no environment dismiss available from
/// the AppDelegate, so we reach through AppKit).
@MainActor func dismissWindow(_ id: String) {
    for window in NSApp.windows where window.identifier?.rawValue.contains(id) == true {
        window.close()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = DictationCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar agent: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)
        coordinator.start()

        // First-run: guide the user through the required grants in a proper
        // window instead of firing the system prompts blind.
        if !coordinator.permissionsGranted {
            coordinator.wantsOnboarding = true
        }
        Log.app.info("VoiceType launched")
    }
}
