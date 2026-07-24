import AppKit
import SwiftUI
import Observation

/// Owns the floating recording HUD panel. The pill is **hidden at rest** and
/// pops up at the bottom of the screen the moment you start dictating,
/// expanding into a live waveform, then hides again once idle. The panel is a
/// non-activating, click-through, all-spaces floating pill: critically it
/// never becomes key, so the app you're dictating into keeps focus and the
/// injected text lands there — not on the HUD.
@MainActor
final class RecordingHUDController {
    /// Fixed canvas large enough to hold the widest/tallest pill state (the error
    /// message) with shadow breathing room. The pill is centered horizontally and
    /// anchored to the bottom edge inside it.
    private static let panelSize = CGSize(width: 320, height: 100)

    /// Window level + collection behavior that make the pill a true overlay:
    /// above ordinary windows, present on **every** Space, and out of the
    /// app-switcher/Exposé cycle. Kept as one constant because it has to be
    /// re-applied, not just set once — see `assertPlacement()`.
    private static let overlayLevel: NSWindow.Level = .statusBar
    private static let overlayBehavior: NSWindow.CollectionBehavior =
        [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

    private let coordinator: DictationCoordinator
    private let panel: NSPanel
    private let hosting: NSHostingView<RecordingHUDView>
    private var spaceChangeObserver: (any NSObjectProtocol)?

    init(coordinator: DictationCoordinator) {
        self.coordinator = coordinator
        self.hosting = NSHostingView(rootView: RecordingHUDView(coordinator: coordinator))

        // The panel is a fixed-size, transparent, click-through canvas. The pill
        // grows and shrinks *inside* it (anchored to the bottom) so the window
        // itself never resizes — that's what made the transition into recording
        // snap with a bad intermediate frame. SwiftUI now owns the whole motion.
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelSize.width, height: Self.panelSize.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.contentView = hosting
        assertPlacement()

        observeSpaceChanges()
        observeState()
        // Nothing to show yet — the pill only appears once dictation starts.
        apply()
    }

    deinit {
        if let spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(spaceChangeObserver)
        }
    }

    // MARK: - Placement

    /// Re-apply the overlay level and all-Spaces stickiness to the panel.
    ///
    /// This is a **repair**, not just configuration. Setting `collectionBehavior`
    /// once at init is not durable: over a long-running session the window server
    /// can drop the panel's all-Spaces membership and re-pin it to whichever
    /// Space it was last shown on. From then on the pill only ever appears on
    /// that one Space — dictation still works everywhere, but the indicator has
    /// silently gone missing from wherever you actually are.
    ///
    /// Confirmed live with `CGSCopySpacesForWindows`: a healthy panel reports
    /// membership in every Space; the wedged one reported exactly one, while
    /// `NSWindow.collectionBehavior` still read back the sticky value we set at
    /// init. AppKit's cached property and the window server had diverged, so
    /// this must assign **unconditionally** — a `!=` guard would read "already
    /// correct" and never repair anything.
    ///
    /// Re-assigning re-syncs the server (verified: membership returns to every
    /// Space within ~100 ms) and is cheap enough to run on every state change and
    /// every Space switch. Same spirit as `HotkeyMonitor`'s health check, which
    /// re-arms an event tap the system killed.
    private func assertPlacement() {
        panel.level = Self.overlayLevel
        panel.collectionBehavior = Self.overlayBehavior
    }

    /// What actually knocks the panel off its all-Spaces membership is internal
    /// to the window server and not something we can observe. Rather than guess
    /// at the trigger, repair on the Space switch itself: it costs two property
    /// assignments, and it means the pill is already sticky by the time the
    /// hotkey is pressed instead of catching up in the first frames of a
    /// dictation.
    private func observeSpaceChanges() {
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.assertPlacement() }
        }
    }

    // MARK: - State observation

    /// Track `coordinator.state` via Observation and re-arm after each change.
    private func observeState() {
        withObservationTracking {
            _ = coordinator.state
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.apply()
                self?.observeState()
            }
        }
    }

    private func apply() {
        // At rest the pill is fully hidden; it appears the moment you start
        // dictating and stays up through processing/injection, then hides again
        // once idle. Re-fit and re-assert front on every change so it tracks the
        // active screen and stays above other windows while visible.
        //
        // Repair placement first — including on the way to hidden, so the panel
        // sits idle in a healthy state and the next dictation pops up on the
        // current Space immediately.
        assertPlacement()
        guard DictationStateKind(coordinator.state) != .idle else {
            panel.orderOut(nil)
            return
        }
        reposition()
        panel.orderFrontRegardless()
    }

    /// Center the fixed canvas horizontally and sit it hard against the bottom of
    /// the active screen. The panel size is constant; only its origin moves (to
    /// follow the active screen), so there is no window resize to animate.
    private func reposition() {
        let size = Self.panelSize
        let screen = activeScreen.visibleFrame
        let x = screen.midX - size.width / 2
        let y = screen.minY
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    /// The screen currently under the pointer, falling back to the main screen.
    private var activeScreen: NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }
}
