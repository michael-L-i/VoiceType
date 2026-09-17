# Headset capture behavior

VoiceType follows the macOS default microphone. Opening a Bluetooth microphone
can switch the headset's playback mode; the start cue acknowledges the hotkey and does not
guarantee that the microphone is already delivering samples.

- Show the original waveform HUD immediately, without a connecting label or
  spinner. Start collecting immediately, including startup audio.
- Schedule the start cue immediately on the hotkey press, before opening the
  microphone. There is no app-imposed readiness wait or extra cue delay.
- Preserve audio collected so far during input recovery. Do not replay the
  initial cue on every recovery.
- Recover when buffers stop, or after five seconds of exact zero-filled buffers.
  This is not a speech-volume threshold. Quiet nonzero microphone noise is valid.
  A hardware mute/noise gate producing exact zeros can also trigger recovery;
  recovery remains bounded to three attempts per recording.
- Scope queued startup/recovery/stop work to the current recording so cancelling
  and starting again cannot stop the new take.

## Hardware verification

Use AirPods as both the macOS input and output, with sound feedback enabled:

1. After music playback, begin dictation. The original waveform bubble should
   appear with an immediate start cue; dictate a 20-second sentence.
2. Repeat several short recordings. Check that the cue is audible and the final
   words are retained. Repeat with sound feedback disabled.
3. Disconnect/reconnect the headset mid-recording. Expect recovery or a visible
   error, never a permanently frozen live meter.
4. Cancel during startup and immediately start again. Check for stale cues or an
   unexpected stop. Repeat while ending a recording's tail grace.
5. Repeat with the built-in microphone and a wired/USB headset.

Unit tests cover missing/zero-filled buffers, quiet pauses,
recovery, and recovery limits. They cannot establish Bluetooth playback timing
or transcription quality on physical hardware.

## Apple references

- [Bluetooth microphone and playback mode changes](https://support.apple.com/en-us/102217)
- [AVCaptureSession: run blocking startup on a serial queue](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [AVCaptureAudioDataOutput audioSettings](https://developer.apple.com/documentation/avfoundation/avcaptureaudiodataoutput/audiosettings)
