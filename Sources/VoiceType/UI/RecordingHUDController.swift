import AppKit
import SwiftUI
import Observation

/// Owns the floating recording HUD panel. The pill is **always present** — a
/// small resting oval at the bottom of the screen that expands into a live
/// waveform while you dictate (the Wispr Flow model: always there, just smaller).
/// The panel is a non-activating, click-through, all-spaces floating pill:
/// critically it never becomes key, so the app you're dictating into keeps focus
/// and the injected text lands there — not on the HUD.
@MainActor
final class RecordingHUDController {
    private let coordinator: DictationCoordinator
    private let panel: NSPanel
    private let hosting: NSHostingView<RecordingHUDView>

    init(coordinator: DictationCoordinator) {
        self.coordinator = coordinator
        self.hosting = NSHostingView(rootView: RecordingHUDView(coordinator: coordinator))

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = hosting

        observeState()
        // Show the resting pill immediately so it's there from launch.
        apply()
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
        // The pill is always on screen; state only changes its size and content.
        // Re-fit and re-assert front on every change so it tracks the active
        // screen and stays above other windows.
        reposition()
        panel.orderFrontRegardless()
    }

    /// Size to fit the current content and center horizontally hard against the
    /// bottom of the active screen.
    private func reposition() {
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        let screen = activeScreen.visibleFrame
        let x = screen.midX - size.width / 2
        // The panel carries ~20pt of transparent margin below the oval (shadow
        // breathing room), so a small offset still leaves the oval near the edge.
        // Sit it hard against the bottom so the resting sliver nearly merges with
        // the screen edge.
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
