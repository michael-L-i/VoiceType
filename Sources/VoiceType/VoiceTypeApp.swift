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
    private var updater: UpdaterController?

    /// Single-instance guard. If another VoiceType is already running — the
    /// classic case is the installed `/Applications` copy plus a dev build, which
    /// share the bundle ID — hand focus to it and bow out before we touch the
    /// menu bar, windows, or permission prompts. Running two copies is what makes
    /// the onboarding window "alternate" and the mic prompt fire repeatedly, since
    /// each process demands its own grant. Runs before `didFinishLaunching` so the
    /// duplicate never sets anything up. `LSMultipleInstancesProhibited` covers the
    /// same-bundle case; this covers two bundles at different paths.
    func applicationWillFinishLaunching(_ notification: Notification) {
        if let other = Self.otherRunningInstance() {
            other.activate()
            Log.app.info("another VoiceType instance is running; deferring to it and exiting")
            exit(0)
        }
    }

    private static func otherRunningInstance() -> NSRunningApplication? {
        guard let id = Bundle.main.bundleIdentifier else { return nil }
        let mePID = NSRunningApplication.current.processIdentifier
        return NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .first { $0.processIdentifier != mePID }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar agent: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)

        // The floating recording pill. Created once; it observes state itself.
        hud = RecordingHUDController(coordinator: coordinator)

        // Auto-updates. Starts Sparkle's scheduled background checks.
        let updater = UpdaterController()
        self.updater = updater
        coordinator.onCheckForUpdates = { updater.checkForUpdates() }

        // Present onboarding via AppKit so it works no matter which SwiftUI
        // scenes happen to be mounted (a SwiftUI Window can't open itself).
        coordinator.onRequestOnboarding = { [weak self] in self?.showOnboarding() }
        coordinator.start()
        coordinator.refreshSystemIntegrationStatus()

        // First-run: guide the user through the required grants in a proper
        // window instead of firing the system prompts blind.
        if !coordinator.permissionsGranted {
            coordinator.wantsOnboarding = true
        }
        Log.app.info("VoiceType launched")
    }

    /// Coming back to the foreground is a strong signal the user may have just
    /// toggled a grant in System Settings. Re-arm the global hotkey so an
    /// Accessibility grant made outside the onboarding window takes effect
    /// without a relaunch.
    func applicationDidBecomeActive(_ notification: Notification) {
        // Re-read grants (also re-arms the hotkey if Accessibility just flipped) —
        // returning to the foreground is the strongest signal a grant changed in
        // System Settings, where nothing calls back.
        coordinator.refreshPermissionStatuses()
        coordinator.refreshSystemIntegrationStatus()
    }

    /// A faceless agent shows nothing when "opened" again from Finder or
    /// Spotlight, which reads as the app being broken. Treat a reopen as a
    /// request to see the app: surface the welcome window, which shows the
    /// hotkey, permission status, and that VoiceType is alive in the menu bar.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { coordinator.wantsOnboarding = true }
        return false
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
