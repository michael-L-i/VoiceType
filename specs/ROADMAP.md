# Roadmap — VoiceType

> The agent grooms issues against this. The human sets direction by editing it.

## Now
- Repo scaffolding: CLAUDE.md, specs/, README, gitignore.
- Decide and lock the app shell (Electron + TS + React) and bootstrap it.

## Next
- Global push-to-talk hotkey + mic capture (macOS first).
- Pluggable transcription interface; wire a local `whisper.cpp` backend.
- Text injection into the focused app (paste/accessibility path).

## Later
- Formatting/cleanup pass (punctuation, casing, filler removal).
- Opt-in cloud transcription provider for speed/quality.
- Windows support.
- Custom vocabulary / dictionary.
