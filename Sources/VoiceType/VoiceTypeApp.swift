import SwiftUI
import AppKit
import VoiceTypeKit

/// App entry point. VoiceType is a regular Dock app: it opens a main window (the
/// Home dashboard) you can see and quit like any other app. Closing the window
/// leaves it running in the background — dictation still works on the hotkey, and
/// clicking the Dock icon brings the window back. The Settings scene is summoned
/// on demand (⌘,); onboarding is presented via AppKit on first run.
@main
struct VoiceTypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Preferences. macOS gives this the standard ⌘, and window chrome. The
        // main Home window is managed by the AppDelegate via AppKit so we keep
        // precise control over launch, close-to-hide, and Dock reopen.
        Settings {
            SettingsView(coordinator: appDelegate.coordinator)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = DictationCoordinator()
    private var mainWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var hud: RecordingHUDController?
    private var updater: UpdaterController?

    /// Single-instance guard. If another VoiceType is already running — the
    /// classic case is the installed `/Applications` copy plus a dev build, which
    /// share the bundle ID — hand focus to it and bow out before we touch any
    /// windows or permission prompts. Running two copies is what makes the
    /// onboarding window "alternate" and the mic prompt fire repeatedly, since
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
        // Regular app: Dock icon and app-switcher entry, a real window, normal
        // quit. (Was a faceless `.accessory` menu-bar agent.)
        NSApp.setActivationPolicy(.regular)

        // The floating recording pill. Created once; it observes state itself.
        hud = RecordingHUDController(coordinator: coordinator)

        // Auto-updates. Starts Sparkle's scheduled background checks.
        let updater = UpdaterController()
        self.updater = updater
        coordinator.onCheckForUpdates = { updater.checkForUpdates() }

        // Open Settings (⌘,) on request from the AppKit-hosted Home window.
        coordinator.onOpenSettings = { Self.openSettingsScene() }

        // Present onboarding via AppKit so it works no matter which SwiftUI
        // scenes happen to be mounted (a SwiftUI Window can't open itself).
        coordinator.onRequestOnboarding = { [weak self] in self?.showOnboarding() }
        coordinator.start()
        coordinator.refreshSystemIntegrationStatus()

        // The main surface: show the Home window on launch.
        showMainWindow()

        // First-run: guide the user through the required grants in a proper
        // window instead of firing the system prompts blind.
        if !coordinator.permissionsGranted {
            coordinator.wantsOnboarding = true
        }
        Log.app.info("VoiceType launched")
    }

    /// Coming back to the foreground is a strong signal the user may have just
    /// toggled a grant in System Settings. Re-read grants (this also re-arms the
    /// global hotkey if Accessibility just flipped, since nothing calls back when
    /// it's changed in System Settings).
    func applicationDidBecomeActive(_ notification: Notification) {
        coordinator.refreshPermissionStatuses()
        coordinator.refreshSystemIntegrationStatus()
    }

    /// Clicking the Dock icon (with no visible window) brings the Home window
    /// back — closing it only hid it; dictation kept running in the background.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    // MARK: - Main window

    /// Create (or re-focus) the Home window hosting the SwiftUI dashboard. The
    /// window is kept alive across closes (`isReleasedWhenClosed = false`) so the
    /// red close button simply hides it — VoiceType keeps dictating in the
    /// background and a Dock click brings the same window straight back.
    private func showMainWindow() {
        if let window = mainWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "VoiceType"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 440, height: 540)
        window.center()
        window.setFrameAutosaveName("VoiceTypeMainWindow")
        window.contentView = NSHostingView(rootView: HomeView(coordinator: coordinator))
        mainWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// Open the SwiftUI `Settings` scene. `\.openSettings` isn't available from an
    /// AppKit-hosted view, so we send the standard responder action instead.
    private static func openSettingsScene() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // MARK: - Onboarding

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
