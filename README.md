<div align="center">

<img src="docs/logo.png" width="128" alt="VoiceType" />

# VoiceType

### Speak anywhere, get clean text instantly — on-device.

A fast, private, open-source voice-dictation app for macOS. Hold a key, talk, and
your words land as clean, punctuated text in whatever app you're using. Your audio
never leaves your Mac — everything runs on-device with Apple Intelligence.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-26%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](./LICENSE)

</div>

---

> **North star:** Speak anywhere, get clean text instantly, with your audio never
> leaving your Mac.

## Why VoiceType

- 🔒 **Private by design.** Audio and transcripts stay on your Mac. No account, no telemetry, no cloud — there's nothing to opt out of.
- ⚡ **Latency is the feature.** Native Swift with Apple's on-device speech model — time-to-text is what we optimize.
- 🎙️ **Press-to-talk anywhere.** A global hotkey works in any app; the cleaned text is inserted right where your cursor is.
- ✨ **Smart cleanup.** Punctuation, capitalization, and filler removal — without ever changing your words.
- 📊 **Your voice, visualized.** A calm Home dashboard tracks your words, pace, and day streaks, with a full activity heatmap and a friendly, on-device usage summary — all computed on your Mac.
- 🧩 **Pluggable engines.** Apple's built-in model by default, with an optional on-device upgrade — NVIDIA Parakeet — you can download and switch to, one at a time.

## Download & install

1. **[⬇ Download VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** from the latest release.
2. Open the DMG and drag **VoiceType** into your **Applications** folder. The app
   is **signed and notarized by Apple**, so it launches with a normal
   double-click — no Gatekeeper workaround needed.
3. Grant the three permissions VoiceType asks for — **Microphone**,
   **Speech Recognition**, and **Accessibility** — and you're set.

> Requires **macOS 26** or later (Apple Silicon).

**Updates are automatic.** VoiceType checks for new versions in the background
(and on demand via **Check for Updates…**) and installs them in place with
[Sparkle](https://sparkle-project.org) — every update is cryptographically signed
and verified. No need to re-download. _(Auto-update works from v0.1.1 onward; the
very first build, v0.1.0, has to be replaced once by hand.)_

## Using it

Hold **Right Option (⌥)** anywhere and start talking. A frosted pill appears
showing a live waveform while it listens; release the key and your cleaned-up text
is inserted into the focused app. Open the window any time to see your **Home
dashboard** — your pace, totals, activity heatmap, and where you dictate. Change
the key, language, engines, and cleanup in **Settings**.

## Engines

Everything runs on-device. Apple's model is built into macOS and selected by
default; you can download other local engines from the **Models** page in the
sidebar and switch between them (one is active at a time).

| Stage | Default (built-in) | Optional on-device downloads |
| --- | --- | --- |
| **Transcription** | Apple `SpeechTranscriber` | **Parakeet TDT 0.6B V3** (NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio)) |
| **Cleanup** | Apple Intelligence (`FoundationModels`) | built-in rules |

Downloadable models are fetched once on demand (no cloud at inference time — your
audio still never leaves the Mac) and run as CoreML on the Apple Neural Engine.
VoiceType automatically falls back to an available engine if your choice can't
run, and always degrades to plain text rather than failing.

> The Parakeet speech model is © NVIDIA, licensed under
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio is
> Apache-2.0.

<a name="privacy"></a>
## Privacy

Audio and transcripts stay on your Mac, full stop — there is no cloud path.
Nothing is logged off-device, and audio is never written to disk. Even the
friendly usage summary is built from aggregate counts only — never your transcript
text. This is a constitutional invariant of the project, not a setting we might
change later.

## Build from source

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Architecture

Native **Swift 6 / SwiftUI** Dock app (macOS 26) with a Home dashboard. Global
push-to-talk hotkey · AVAudioEngine mic capture · pluggable on-device
transcription · pluggable cleanup · paste/Accessibility text injection · a
floating recording HUD. The core (`VoiceTypeKit`) is pure and unit-tested; the app
target holds the system engines and UI. Details live in [`CLAUDE.md`](./CLAUDE.md)
and evolve via `specs/`.

## License

[MIT](./LICENSE) © 2026 Michael Li.

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
│   └── VoiceType/     # app: hotkey, audio, engines, injection, dashboard UI
├── Tests/             # VoiceTypeKit unit tests
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── specs/             # the human's surface — product direction (agent doesn't edit)
└── README.md
```
