import AppKit
import SwiftUI
import Observation

/// Owns the floating recording HUD panel. The pill sits at the bottom of the
/// screen: a small resting sliver (or nothing at all, per the "resting
/// indicator" setting) that expands into a live waveform the moment you start
/// dictating, then settles back once idle. The panel is a non-activating,
/// click-through, all-spaces floating pill: critically it never becomes key, so
/// the app you're dictating into keeps focus and the injected text lands there
/// — not on the HUD.
///
/// The panel itself is **never ordered out** — resting is drawn, not hidden.
/// See `present()` for why that distinction is the whole ballgame.
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
    private var screenChangeObserver: (any NSObjectProtocol)?

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
        // The panel is never ordered out, so it also has to survive ⌘H and
        // "Hide Others" — otherwise AppKit pulls it off screen and we lose the
        // all-Spaces membership that staying on screen exists to protect.
        panel.canHide = false
        panel.ignoresMouseEvents = true
        panel.contentView = hosting
        assertPlacement()

        observeSpaceChanges()
        observeScreenChanges()
        observeState()
        // Put the panel on screen straight away and leave it there for the
        // lifetime of the app — at rest it simply draws nothing.
        present()
    }

    deinit {
        if let spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(spaceChangeObserver)
        }
        if let screenChangeObserver {
            NotificationCenter.default.removeObserver(screenChangeObserver)
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
        // Write a *different* mask first. The whole premise above is that
        // AppKit's cached `collectionBehavior` has diverged from the window
        // server's — and a setter handed the value it already believes it holds
        // is free to swallow the write before it ever reaches the server, which
        // is the one thing this repair needs to happen. Toggling `.ignoresCycle`
        // is the smallest difference that forces the write through; it leaves
        // the Spaces flags untouched in the intermediate mask, so there is no
        // window the server could use to re-home the panel mid-repair.
        panel.collectionBehavior = Self.overlayBehavior.subtracting(.ignoresCycle)
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
            Task { @MainActor in self?.present() }
        }
    }

    /// Plugging in a display, unplugging one, waking from sleep or moving the
    /// Dock all move the bottom-centre of "the active screen" out from under the
    /// panel. The frame is only otherwise recomputed on a state change, so
    /// without this the pill sits at coordinates that no longer describe
    /// anywhere visible — which looks exactly like it vanished.
    private func observeScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.present() }
        }
    }

    // MARK: - State observation

    /// Track `coordinator.state` via Observation and re-arm after each change.
    private func observeState() {
        withObservationTracking {
            _ = coordinator.state
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.present()
                self?.observeState()
            }
        }
    }

    /// Put the panel where it belongs and make sure it is on screen. Every event
    /// that could have disturbed it funnels through here — a dictation state
    /// change, a Space switch, a display change — because "keep it there" means
    /// re-showing it, not just re-configuring it. Ordering an already-visible
    /// panel front is free, and it is the only thing that recovers a panel
    /// something else pulled off screen.
    ///
    /// The panel is **never ordered out**. Resting is a drawing decision, made
    /// by `RecordingHUDView` (it fades the pill to nothing, honouring the
    /// "resting indicator" setting) — not a window decision. Ordering out is
    /// what broke the pill: a `.canJoinAllSpaces` window's per-Space membership
    /// is established when it is *ordered in*, across the Spaces that exist at
    /// that instant. Hidden, it belongs to no Space at all; and a later
    /// `orderFrontRegardless()` issued from a background app can re-home it onto
    /// a single Space instead of all of them. That is the reported failure
    /// exactly: it works for a day or two, then new Spaces appear (every window
    /// sent to full screen mints one) and the pill is pinned to whichever Space
    /// is frontmost — often Chrome's — and never shows up where you actually
    /// are.
    ///
    /// A panel that never leaves the screen keeps its membership alive, which is
    /// how this worked before the pill learned to hide. It costs nothing: the
    /// panel is transparent, borderless and click-through, so an "invisible"
    /// panel and an ordered-out one are indistinguishable to the user.
    private func present() {
        assertPlacement()
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
