import AppKit

/// Audible start/stop cues for dictation, using built-in system sounds so
/// there are no assets to ship. One long-lived instance (owned by the
/// coordinator) retains each cue until it finishes playing: `NSSound.play()`
/// is asynchronous, so the fire-and-forget `NSSound(named:)?.play()` this
/// replaces could be deallocated mid-play and go silent at random.
@MainActor
final class SoundFeedback {
    /// Cues that may still be playing, retained so ARC can't cut them off.
    /// Pruned of finished sounds on each play; never more than a couple deep.
    private var live: [NSSound] = []

    func start(enabled: Bool) { play("Tink", enabled: enabled) }
    func stop(enabled: Bool) { play("Pop", enabled: enabled) }

    private func play(_ name: String, enabled: Bool) {
        guard enabled else { return }
        live.removeAll { !$0.isPlaying }
        guard let sound = NSSound(named: name) else { return }
        // The named-sound cache can hand back an instance that's mid-play, and
        // play() on an already-playing sound silently no-ops. Rewind it first.
        if sound.isPlaying { sound.stop() }
        live.append(sound)
        sound.play()
    }
}
