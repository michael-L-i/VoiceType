import AppKit
import SwiftUI
import Observation

/// Owns the floating recording HUD panel and shows/hides it as dictation state
/// changes. The panel is a non-activating, click-through, all-spaces floating
/// pill: critically it never becomes key, so the app you're dictating into keeps
/// focus and the injected text lands there — not on the HUD.
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
        switch DictationStateKind(coordinator.state) {
        case .idle:
            panel.orderOut(nil)
        default:
            reposition()
            panel.orderFrontRegardless()
        }
    }

    /// Size to fit the current content and center horizontally near the bottom
    /// of the active screen.
    private func reposition() {
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        let screen = activeScreen.visibleFrame
        let x = screen.midX - size.width / 2
        let y = screen.minY + 120
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
