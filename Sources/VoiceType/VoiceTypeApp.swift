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
            // The ⌘, window needs an explicit size; the in-window Settings page
            // (SettingsView used in RootView) fills its detail area instead.
            SettingsView(coordinator: appDelegate.coordinator)
                .frame(width: 520, height: 460)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = DictationCoordinator()
    private var mainWindow: NSWindow?
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

        // VoiceType has a light identity (warm coral on white), so pin the whole
        // app to the Aqua appearance rather than following the system into Dark
        // Mode. Covers the Home window, the floating HUD, and Settings at once.
        NSApp.appearance = NSAppearance(named: .aqua)

        // The floating recording pill. Created once; it observes state itself.
        hud = RecordingHUDController(coordinator: coordinator)

        // Auto-updates. Starts Sparkle's scheduled background checks.
        let updater = UpdaterController()
        self.updater = updater
        coordinator.onCheckForUpdates = { updater.checkForUpdates() }
        updater.onUpdateAvailabilityChange = { [coordinator] available in
            coordinator.updateAvailable = available
        }

        // Open Settings (⌘,) on request from the AppKit-hosted Home window.
        coordinator.onOpenSettings = { Self.openSettingsScene() }

        // Setup is now a tab inside the Home window (RootView switches to it when
        // `wantsOnboarding` flips); just make sure the window is up and focused.
        coordinator.onRequestOnboarding = { [weak self] in self?.showMainWindow() }
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
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "VoiceType"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 720, height: 520)
        window.center()
        window.setFrameAutosaveName("VoiceTypeMainWindow")
        window.contentView = NSHostingView(rootView: RootView(coordinator: coordinator))
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
}
