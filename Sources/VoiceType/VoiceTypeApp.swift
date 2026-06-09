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
        .menuBarExtraStyle(.window)

        // Preferences. macOS gives this the standard ⌘, and window chrome.
        Settings {
            SettingsView(coordinator: appDelegate.coordinator)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = DictationCoordinator()
    private var onboardingWindow: NSWindow?
    private var hud: RecordingHUDController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar agent: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)

        // The floating recording pill. Created once; it observes state itself.
        hud = RecordingHUDController(coordinator: coordinator)

        // Present onboarding via AppKit so it works no matter which SwiftUI
        // scenes happen to be mounted (a SwiftUI Window can't open itself).
        coordinator.onRequestOnboarding = { [weak self] in self?.showOnboarding() }
        coordinator.start()

        // First-run: guide the user through the required grants in a proper
        // window instead of firing the system prompts blind.
        if !coordinator.permissionsGranted {
            coordinator.wantsOnboarding = true
        }
        Log.app.info("VoiceType launched")
    }

    /// Create (or re-focus) the onboarding window, hosting the SwiftUI view.
    private func showOnboarding() {
        if let window = onboardingWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let root = OnboardingView(coordinator: coordinator) { [weak self] in
            self?.coordinator.wantsOnboarding = false
            self?.onboardingWindow?.close()
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "Welcome to VoiceType"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: root)
        window.delegate = onboardingDelegate
        onboardingWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // Reset the onboarding flag when the user closes the window directly.
    private lazy var onboardingDelegate = OnboardingWindowDelegate { [weak self] in
        self?.coordinator.wantsOnboarding = false
    }
}

/// Tracks manual closes of the onboarding window so `wantsOnboarding` stays in
/// sync (otherwise re-requesting it after a manual close would no-op).
private final class OnboardingWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: @MainActor () -> Void
    init(onClose: @escaping @MainActor () -> Void) { self.onClose = onClose }
    func windowWillClose(_ notification: Notification) {
        MainActor.assumeIsolated { onClose() }
    }
}
