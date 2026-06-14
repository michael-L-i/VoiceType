import AppKit
import VoiceTypeKit

/// Watches the push-to-talk modifier globally and reports press/release.
///
/// We use a **CGEventTap** rather than an `NSEvent` global monitor. A global
/// `NSEvent` monitor is observe-only and, critically, has no recovery path when
/// macOS silently disables it — which happens when the event-delivery callback is
/// briefly slow (e.g. while the audio graph reconfigures as AirPods connect). An
/// event tap delivers an explicit `tapDisabledBy…` event we can re-enable from,
/// plus we run a 1 s health check that re-arms a tap the system killed for any
/// other reason (sleep/wake, route changes). This is the fix for the classic
/// "the hotkey just randomly stops working" bug.
///
/// The tap is **listen-only** — it never consumes the modifier, so Right Option
/// (etc.) still works normally for typing. A modifier's `flagsChanged` event
/// carries the post-change state, so the trigger keyCode firing with its flag set
/// = down, and without it = up. Creating the tap requires Accessibility / Input
/// Monitoring consent — `Permissions` gates this, and `DictationCoordinator`
/// re-arms us once the grant flips.
@MainActor
final class HotkeyMonitor {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    private(set) var trigger: Hotkey.Trigger
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var healthTimer: Timer?
    private var isDown = false

    init(trigger: Hotkey.Trigger) {
        self.trigger = trigger
    }

    func updateTrigger(_ trigger: Hotkey.Trigger) {
        self.trigger = trigger
        isDown = false
    }

    /// True once a tap is installed. Lets the coordinator tell "armed" from
    /// "couldn't arm yet because consent was missing".
    var isActive: Bool { eventTap != nil }

    func start() {
        stop()

        let mask = CGEventMask(1) << CGEventType.flagsChanged.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                if let refcon {
                    let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                    // The source is attached to the main run loop, so this fires
                    // on the main thread — safe to hop onto the main actor.
                    MainActor.assumeIsolated { monitor.handleTapEvent(type: type, event: event) }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            // Most commonly: Accessibility / Input Monitoring not granted yet.
            // The coordinator re-calls start() once the grant flips.
            Log.hotkey.error("could not create event tap (input monitoring not granted yet)")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        runLoopSource = source

        healthTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.healthCheck() }
        }
        Log.hotkey.info("event tap monitoring \(self.trigger.rawValue, privacy: .public)")
    }

    func stop() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
        healthTimer?.invalidate()
        healthTimer = nil
        isDown = false
    }

    private func handleTapEvent(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // The system disabled the tap (a slow callback, secure input, etc.).
            // Re-enable it in place and release any half-tracked hold so we don't
            // get wedged believing the key is still down.
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            if isDown { isDown = false; onRelease?() }
            Log.hotkey.info("re-enabled disabled event tap")

        case .flagsChanged:
            let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
            guard keyCode == Self.keyCode(for: trigger) else { return }
            let active = event.flags.contains(Self.flag(for: trigger))
            if active && !isDown {
                isDown = true
                onPress?()
            } else if !active && isDown {
                isDown = false
                onRelease?()
            }

        default:
            break
        }
    }

    /// Re-arm a tap the system killed without delivering a disable event (seen
    /// across sleep/wake and some audio-route transitions), and recover a stale
    /// "held" state if a key-up was ever dropped. Cheap; safe to run on a timer.
    private func healthCheck() {
        if let tap = eventTap, !CGEvent.tapIsEnabled(tap: tap) {
            CGEvent.tapEnable(tap: tap, enable: true)
            Log.hotkey.info("health check re-enabled event tap")
        }
        if isDown, !NSEvent.modifierFlags.contains(Self.nsFlag(for: trigger)) {
            isDown = false
            Log.hotkey.info("recovered stale \(self.trigger.rawValue, privacy: .public) down state")
            onRelease?()
        }
    }

    // Hardware key codes for the modifier keys (left/right are distinct), which is
    // how we tell left vs. right Option apart — CGEventFlags only reports "an
    // Option is down", not which side.
    private static func keyCode(for trigger: Hotkey.Trigger) -> UInt16 {
        switch trigger {
        case .leftOption: return 58
        case .rightOption: return 61
        case .rightCommand: return 54
        case .fn: return 63
        }
    }

    private static func flag(for trigger: Hotkey.Trigger) -> CGEventFlags {
        switch trigger {
        case .leftOption, .rightOption: return .maskAlternate
        case .rightCommand: return .maskCommand
        case .fn: return .maskSecondaryFn
        }
    }

    // Used only by the health check, which reads live state via NSEvent.
    private static func nsFlag(for trigger: Hotkey.Trigger) -> NSEvent.ModifierFlags {
        switch trigger {
        case .leftOption, .rightOption: return .option
        case .rightCommand: return .command
        case .fn: return .function
        }
    }
}
