# Roadmap — VoiceType

> The agent grooms issues against this. The human sets direction by editing it.

## Now
- Verify the macOS 14–15 path on real hardware: Apple's legacy on-device
  recognizer has never actually run outside availability checks.
- Decide what a first public release includes, and cut it.

## Next
- Selection should follow the resolver: after downloading a model, the Models
  page still shows an unavailable engine as "Active" while another one runs.
- Cloud transcription/cleanup as an opt-in provider, behind the consent gate.
- Windows support.

## Later
- Streaming/partial results instead of the current batch (speak → release → text).
- Per-app formatting profiles (shell register in a terminal, prose elsewhere).

## Shipped
- Native Swift 6 / SwiftUI Dock app (supersedes the earlier Electron + TS + React
  plan — Mac-only, latency-first, and direct access to Apple's on-device models).
- Global push-to-talk hotkey, mic capture, and text injection into the focused app.
- Pluggable transcription: Apple on-device, Parakeet, Whisper Base, Nemotron.
- Cleanup pass: deterministic rules plus optional on-device Apple Intelligence.
- Custom vocabulary / dictionary, transcript history, usage insights.
- Localized UI following the macOS language.
- macOS 14+ support with availability-gated macOS 26 features.
