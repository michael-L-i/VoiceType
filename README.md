<div align="center">

<img src="docs/logo.png" width="120" alt="VoiceType" />

# VoiceType

### Speak anywhere, get clean text instantly — on-device.

A fast, private, open-source voice-dictation app for macOS. Hold a key, talk, and
your words land as clean, punctuated text in whatever app you're using. Your audio
never leaves your Mac unless you choose to turn on a cloud engine.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-5C75EB?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=5C75EB)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-26%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)

</div>

---

> **North star:** Speak anywhere, get clean text instantly, with your audio never
> leaving your control unless you opt in.

## Why VoiceType

- 🔒 **Private by default.** Audio and transcripts stay on your Mac. Any cloud path is opt-in, clearly labeled, and off until you turn it on.
- ⚡ **Latency is the feature.** Native Swift with Apple's on-device speech model — time-to-text is what we optimize.
- 🎙️ **Press-to-talk anywhere.** A global hotkey works in any app; the cleaned text is inserted right where your cursor is.
- ✨ **Smart cleanup.** Punctuation, capitalization, and filler removal — without ever changing your words.
- 🧩 **Pluggable engines.** On-device by default, with a local Whisper fallback and an optional Groq cloud upgrade.
- 🪶 **A calm little menu-bar app.** No Dock icon, no account, no telemetry. A floating pill shows you're being heard.

## Download & install

1. **[⬇ Download VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** from the latest release.
2. Open the DMG and drag **VoiceType** into your **Applications** folder.
3. **First launch:** VoiceType is open-source and not yet notarized by Apple, so a
   normal double-click is blocked by Gatekeeper. The one-time fix:
   **right-click VoiceType → Open → Open.** macOS remembers your choice — every
   launch after that is a plain double-click.
4. Grant the three permissions VoiceType asks for — **Microphone**,
   **Speech Recognition**, and **Accessibility** — and you're set.

> Requires **macOS 26** or later (Apple Silicon).

**Updates are automatic.** VoiceType checks for new versions in the background
(and on demand via **Check for Updates…** in the menu) and installs them in place
with [Sparkle](https://sparkle-project.org) — every update is cryptographically
signed and verified. No need to re-download. _(Auto-update works from v0.1.1
onward; the very first build, v0.1.0, has to be replaced once by hand.)_

## Using it

Hold **Right Option (⌥)** anywhere and start talking. A frosted pill appears
showing a live waveform while it listens; release the key and your cleaned-up text
is inserted into the focused app. Change the key, language, engines, and cleanup
in **Settings**.

## Engines

| Stage | Default (on-device) | Local fallback | Opt-in cloud |
| --- | --- | --- | --- |
| **Transcription** | Apple `SpeechTranscriber` | `whisper.cpp` | Groq `whisper-large-v3-turbo` |
| **Cleanup** | Apple Intelligence (`FoundationModels`) | built-in rules | Groq (`llama-3.1-8b-instant`) |

VoiceType automatically uses the best engine that's available and permitted, and
always degrades to plain text rather than failing.

<a name="privacy"></a>
## Privacy

Audio and transcripts stay on-device by default. The cloud engines (Groq) are
inert until you flip a single master **"Enable cloud"** switch and add your own
API key, which is stored in the macOS Keychain. Nothing is logged off-device, and
audio is never written to disk. This is a constitutional invariant of the project,
not a setting we might change later.

## Build from source

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Architecture

Native **Swift 6 / SwiftUI** menu-bar app (macOS 26). Global push-to-talk hotkey ·
AVAudioEngine mic capture · pluggable on-device transcription · pluggable cleanup ·
paste/Accessibility text injection · a floating recording HUD. The core
(`VoiceTypeKit`) is pure and unit-tested; the app target holds the system engines
and UI. Details live in [`CLAUDE.md`](./CLAUDE.md) and evolve via `specs/`.

## How this repo is run

VoiceType is a standalone product repo run day-to-day by an agent (the **outer
loop**: triage → review → merge/escalate), with a human supplying **taste** by
editing `specs/`. It links the [`@aros/*`](../agent-repo-os) framework during
local dev. See [`CLAUDE.md`](./CLAUDE.md) for the operating rules.

## Repo layout

```
VoiceType/
├── CLAUDE.md          # operating rules for the agent
├── Package.swift      # SwiftPM: VoiceTypeKit (core) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # pure, tested core: protocols, pipeline, cleanup, resolver
│   └── VoiceType/     # app: menu bar, hotkey, audio, engines, injection, UI
├── Tests/             # VoiceTypeKit unit tests
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift
├── Resources/         # Info.plist · entitlements · AppIcon
├── specs/             # the human's surface — product direction (agent doesn't edit)
└── README.md
```
