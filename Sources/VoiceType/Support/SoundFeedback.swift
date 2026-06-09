import AppKit

/// Subtle audible cues for start/stop of dictation. Kept tiny and optional —
/// honors the `soundFeedback` setting. Uses built-in system sounds so there are
/// no assets to ship.
struct SoundFeedback {
    var enabled: Bool

    func start() { play("Tink") }
    func stop() { play("Pop") }

    private func play(_ name: String) {
        guard enabled else { return }
        NSSound(named: name)?.play()
    }
}
