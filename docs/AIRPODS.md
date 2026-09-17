# Headset capture behavior

VoiceType follows the macOS default microphone. Opening a Bluetooth microphone
can switch the headset's playback mode; capture startup and a ready cue are not
simultaneous operations.

- Show the HUD immediately, with a spinner and “Connecting microphone…” while
  waiting for usable audio. Start collecting immediately, including startup audio.
- Play the start cue once, after 200 ms of nonzero, finite sample buffers. This
  avoids scheduling the cue immediately before opening the Bluetooth microphone.
- Show the connecting indicator again during input recovery, preserving audio
  collected so far. Do not replay the initial cue on every recovery.
- Recover when buffers stop, or after five seconds of exact zero-filled buffers.
  This is not a speech-volume threshold. Quiet nonzero microphone noise is valid.
  A hardware mute/noise gate producing exact zeros can also trigger recovery;
  recovery remains bounded to three attempts per recording.
- Scope queued startup/recovery/ready work to the current recording so cancelling
  and starting again cannot deliver an old ready cue or stop the new take.

## Hardware verification

Use AirPods as both the macOS input and output, with sound feedback enabled:

1. After music playback, begin dictation. The connecting indicator should appear
   immediately; wait for the ready cue, then dictate a 20-second sentence.
2. Repeat several short recordings. Check that the cue is audible and the final
   words are retained. Repeat with sound feedback disabled.
3. Disconnect/reconnect the headset mid-recording. Expect recovery or a visible
   error, never a permanently frozen live meter.
4. Cancel during startup and immediately start again. Check for stale cues or an
   unexpected stop. Repeat while ending a recording's tail grace.
5. Repeat with the built-in microphone and a wired/USB headset.

Unit tests cover readiness timing, missing/zero-filled buffers, quiet pauses,
recovery, and recovery limits. They cannot establish Bluetooth playback timing
or transcription quality on physical hardware.

## Apple references

- [Bluetooth microphone and playback mode changes](https://support.apple.com/en-us/102217)
- [AVCaptureSession: run blocking startup on a serial queue](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [AVCaptureAudioDataOutput audioSettings](https://developer.apple.com/documentation/avfoundation/avcaptureaudiodataoutput/audiosettings)
