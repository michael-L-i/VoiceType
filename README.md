<div align="center">

<img src="docs/logo.png" width="128" alt="VoiceType" />

# VoiceType

### Speak anywhere, in your language — clean text instantly, all on-device.

A fast, private, open-source voice-dictation app for macOS. Hold a key, talk —
in English, 中文, Español, 日本語, or 30+ other languages — and your words land
as clean, punctuated text in whatever app you're using. Your audio never leaves
your Mac — everything runs on-device.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Languages](https://img.shields.io/badge/dictation-30%2B%20languages-F2743E)](#languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](./LICENSE)

**English** ·
[简体中文](./docs/readme/README.zh-Hans.md) ·
[Deutsch](./docs/readme/README.de.md) ·
[Español](./docs/readme/README.es.md) ·
[Français](./docs/readme/README.fr.md) ·
[Italiano](./docs/readme/README.it.md) ·
[日本語](./docs/readme/README.ja.md) ·
[한국어](./docs/readme/README.ko.md) ·
[Nederlands](./docs/readme/README.nl.md) ·
[Polski](./docs/readme/README.pl.md) ·
[Português](./docs/readme/README.pt-BR.md) ·
[Русский](./docs/readme/README.ru.md) ·
[Svenska](./docs/readme/README.sv.md) ·
[Türkçe](./docs/readme/README.tr.md) ·
[Українська](./docs/readme/README.uk.md) ·
[Tiếng Việt](./docs/readme/README.vi.md)

</div>

---

> **North star:** Speak anywhere, get clean text instantly, with your audio never
> leaving your Mac.

## Why VoiceType

- 🔒 **Private by design.** Audio and transcripts stay on your Mac. No account, no telemetry, no cloud — there's nothing to opt out of.
- ⚡ **Latency is the feature.** Native Swift with Apple's on-device speech model — time-to-text is what we optimize.
- 🌍 **Speaks your language.** Dictate in 30+ languages — not just English. Cleanup understands each language's conventions (full-width 中文 punctuation, spoken 句号, language-aware fillers), the app picks an engine that actually supports your language, and the UI itself ships in 16 languages.
- 🎙️ **Press-to-talk anywhere.** A global hotkey works in any app; the cleaned text is inserted right where your cursor is.
- ✨ **Smart cleanup.** Punctuation, capitalization, and filler removal — without ever changing your words.
- 📊 **Your voice, visualized.** A calm Home dashboard tracks your words, pace, and day streaks, with a full activity heatmap and a friendly, on-device usage summary — all computed on your Mac.
- 🧩 **Pluggable engines.** Apple's built-in model by default, with an optional on-device upgrade — NVIDIA Parakeet — you can download and switch to, one at a time.

## Download

**[Download VoiceType for macOS](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg).**
Requires macOS 14 or later on Apple silicon.

Open the DMG, move VoiceType to Applications, and follow the prompts on first
launch.

## How it works

Press and hold your chosen shortcut, speak, then release to insert the text into
the current app. Configure your shortcut, language, and models in Settings.

## Engines

Everything runs on-device. Apple's model is built into macOS and selected by
default; you can download other local engines from the **Models** page in the
sidebar and switch between them (one is active at a time).

| Stage | Default (built-in) | Optional alternatives (on-device) |
| --- | --- | --- |
| **Transcription** | **Apple Speech** — `SpeechTranscriber` on macOS 26+, on-device `SFSpeechRecognizer` on macOS 14–15 | **Parakeet TDT 0.6B V3** (NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — downloaded on demand |
| **Cleanup** | Built-in rules (instant, deterministic) | Apple Intelligence (`FoundationModels`, macOS 26+) — built into macOS, no download |

Downloadable models are fetched once on demand (no cloud at inference time — your
audio still never leaves the Mac) and run as CoreML on the Apple Neural Engine.
VoiceType automatically falls back to an available engine if your choice can't
run, and always degrades to plain text rather than failing.

> The Parakeet speech model is © NVIDIA, licensed under
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio is
> Apache-2.0. Whisper is OpenAI (MIT); WhisperKit is MIT.

<a name="languages"></a>
## Languages

VoiceType is multilingual end-to-end, not English-with-subtitles:

- **Dictate in 30+ languages** — English, 中文, Español, Français, Deutsch,
  日本語, 한국어, Português, Русский, Tiếng Việt, and more. You pick the
  language; VoiceType never guesses.
- **Engines are matched to your language.** Each speech model declares what it
  supports (Parakeet is European-only; Nemotron covers 40 locales including
  Chinese; Whisper is broadly multilingual; Apple's list comes from macOS).
  Models that can't handle your language gray out, and VoiceType switches to
  one that can.
- **Cleanup knows the language.** Each language ships a small, reviewable
  "language pack": its filler words (嗯/呃, ähm, euh — never words that carry
  meaning), its punctuation conventions (full-width 。，？ for Chinese and
  Japanese, spoken 句号/読点 rendered as marks), and its question heuristics.
- **The app itself is localized** into 16 languages, following your macOS
  system language (per-app override in System Settings works too).

Your language missing, or a translation off? Adding a language is deliberately
small — a UI translation needs no Swift at all — see
[docs/LOCALIZATION.md](./docs/LOCALIZATION.md).

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

## Contributing

Contributions are welcome. Please read the [contribution guide](./CONTRIBUTING.md)
for development requirements, privacy expectations, and pull-request guidance.
Want VoiceType in your language? [docs/LOCALIZATION.md](./docs/LOCALIZATION.md)
has the checklist — a UI translation needs no Swift at all, and dictation
quality for a new language is one well-documented file.
All participants are expected to follow the [Code of Conduct](./CODE_OF_CONDUCT.md).
For vulnerabilities, follow the private reporting process in our
[Security Policy](./SECURITY.md).

## Architecture

Native **Swift 6 / SwiftUI** Dock app (macOS 14+) with a Home dashboard. Global
push-to-talk hotkey · AVAudioEngine mic capture · pluggable on-device
transcription · pluggable cleanup · paste/Accessibility text injection · a
floating recording HUD. The core (`VoiceTypeKit`) is pure and unit-tested; the app
target holds the system engines and UI. Details live in [`CLAUDE.md`](./CLAUDE.md)
and evolve via `specs/`.

## License

[MIT](./LICENSE) © 2026 Michael Li.

Third-party components and on-device models bundled with the app retain their own
licenses — see [`THIRD_PARTY_LICENSES.md`](./THIRD_PARTY_LICENSES.md) (also shipped
inside the app bundle).

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
