import AppKit
import VoiceTypeKit

/// Watches the push-to-talk modifier globally and reports press/release.
///
/// We monitor `.flagsChanged` events both globally (other apps focused) and
/// locally (our own windows). A modifier's flags-changed event carries the
/// post-change state, so the same keyCode firing with the flag set = down, and
/// without it = up. Global key monitoring requires Accessibility/Input
/// Monitoring consent — `Permissions` gates this.
@MainActor
final class HotkeyMonitor {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    private(set) var trigger: Hotkey.Trigger
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isDown = false

    init(trigger: Hotkey.Trigger) {
        self.trigger = trigger
    }

    func updateTrigger(_ trigger: Hotkey.Trigger) {
        self.trigger = trigger
        isDown = false
    }

    func start() {
        stop()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
            return event
        }
        Log.hotkey.info("monitoring \(self.trigger.rawValue, privacy: .public)")
    }

    func stop() {
        if let g = globalMonitor { NSEvent.removeMonitor(g); globalMonitor = nil }
        if let l = localMonitor { NSEvent.removeMonitor(l); localMonitor = nil }
        isDown = false
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode == Self.keyCode(for: trigger) else { return }
        let active = event.modifierFlags.contains(Self.flag(for: trigger))
        if active && !isDown {
            isDown = true
            onPress?()
        } else if !active && isDown {
            isDown = false
            onRelease?()
        }
    }

    // Hardware key codes for the modifier keys (left/right are distinct).
    private static func keyCode(for trigger: Hotkey.Trigger) -> UInt16 {
        switch trigger {
        case .leftOption: return 58
        case .rightOption: return 61
        case .rightCommand: return 54
        case .fn: return 63
        }
    }

    private static func flag(for trigger: Hotkey.Trigger) -> NSEvent.ModifierFlags {
        switch trigger {
        case .leftOption, .rightOption: return .option
        case .rightCommand: return .command
        case .fn: return .function
        }
    }
}
