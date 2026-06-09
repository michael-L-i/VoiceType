# VoiceType

A fast, private, open-source voice-dictation app — a Wispr Flow clone.

Hold a global hotkey, speak, and your words are transcribed and typed into
whatever app is focused, with light AI cleanup (punctuation, casing, filler
removal). **Latency and privacy are the product:** audio and transcripts stay
on-device by default; any cloud path is opt-in and clearly labeled.

> **North star:** Speak anywhere, get clean text instantly, with your audio never
> leaving your control unless you opt in.

## Status

Working prototype. Native **Swift 6 / SwiftUI** menu-bar app for macOS 26.
Hold the dictation key → speak → clean text is inserted into the focused app.

### Build & run

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
open VoiceType.app      # launch the menu-bar agent
```

On first launch, VoiceType walks you through three grants — **Microphone**,
**Speech Recognition**, and **Accessibility** — then lives in the menu bar.
Hold **Right Option** (configurable) and speak; release to insert.

- **Transcription:** Apple on-device `SpeechTranscriber` by default, with a local
  `whisper.cpp` fallback and opt-in Groq cloud.
- **Cleanup:** Apple `FoundationModels` on-device, falling back to deterministic
  rules, with opt-in Groq cloud. Cloud is off by default and clearly gated.

## Download & install

1. Grab **`VoiceType.dmg`** from the
   [latest release](../../releases/latest).
2. Open the DMG and drag **VoiceType** into your **Applications** folder.
3. **First launch:** VoiceType is open-source and not yet notarized by Apple
   (no Developer account), so a normal double-click gets blocked by Gatekeeper.
   The one-time fix: **right-click VoiceType → Open → Open**. macOS remembers
   your choice, so every launch after that is a plain double-click.

On first run, grant the three permissions VoiceType asks for — **Microphone**,
**Speech Recognition**, and **Accessibility** — then hold **Right Option** and
speak; release to insert the cleaned-up text into whatever app is focused.

> Requires **macOS 26**. Everything runs on-device by default; any cloud path is
> opt-in and clearly labeled.

## How this repo is run

VoiceType is a standalone product repo run day-to-day by an agent (the **outer
loop**: triage → review → merge/escalate), with a human supplying **taste** by
editing `specs/`. It links the [`@aros/*`](../agent-repo-os) framework during
local dev. See [`CLAUDE.md`](./CLAUDE.md) for the operating rules.

## Architecture

Native **Swift 6 / SwiftUI** menu-bar app (macOS 26). Global push-to-talk hotkey ·
AVAudioEngine mic capture · pluggable on-device transcription (Apple
`SpeechTranscriber`, `whisper.cpp` fallback, opt-in Groq cloud) · pluggable
cleanup (Apple `FoundationModels`, rule-based floor, opt-in Groq cloud) ·
paste/Accessibility text injection. Details live in `CLAUDE.md` and evolve via
`specs/`.

## Repo layout

```
VoiceType/
├── CLAUDE.md          # operating rules for the agent
├── Package.swift      # SwiftPM: VoiceTypeKit (core) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # pure, tested core: protocols, pipeline, cleanup, resolver
│   └── VoiceType/      # app: menu bar, hotkey, audio, engines, injection, UI
├── Tests/             # VoiceTypeKit unit tests
├── Scripts/build-app.sh
├── Resources/         # Info.plist + entitlements
├── specs/             # the human's surface — product direction (agent doesn't edit)
│   ├── CONSTITUTION.md
│   ├── TASTE.md
│   └── ROADMAP.md
└── README.md
```
