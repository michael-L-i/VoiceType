<div align="center">

<img src="docs/logo.png" width="128" alt="VoiceType" />

# VoiceType

### Dictation in 33 languages. Clean text instantly. All on-device.

A fast, private, open-source voice-dictation app for macOS. Hold a key, talk —
in English, 中文, Español, 日本語, العربية, हिन्दी, Tiếng Việt, or 26 more — and
your words land as clean, punctuated text in whatever app you're using.

Multilingual **end to end**: the speech model is matched to your language, the
cleanup pass knows your language's punctuation and filler words, and the app's
own interface ships in 16 languages. Every one of them runs **on-device** — your
audio never leaves your Mac, in any language.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Dictation languages](https://img.shields.io/badge/dictation-33%20languages-F2743E)](./docs/LANGUAGES.md)
&nbsp;[![Interface languages](https://img.shields.io/badge/interface-16%20languages-F2743E)](./docs/LANGUAGES.md#interface-languages)
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

- 🌍 **Multilingual end to end, not English-with-subtitles.** Dictate in [33 languages](./docs/LANGUAGES.md). VoiceType picks a speech model that actually supports your language, cleans up using *that* language's conventions — full-width 中文 punctuation, spoken 句号, French's space before « ! », Turkish's dotted İ, language-aware fillers — and ships its own interface in 16 languages.
- 🔒 **Private in every language.** Audio and transcripts stay on your Mac. No account, no telemetry, no cloud — there's no "send the hard languages to a server" path to opt out of.
- ⚡ **Latency is the feature.** Native Swift with on-device speech models — time-to-text is what we optimize.
- 🎙️ **Press-to-talk anywhere.** A global hotkey works in any app; the cleaned text is inserted right where your cursor is.
- ✨ **Smart cleanup.** Punctuation, capitalization, and filler removal — without ever changing your words.
- 📊 **Your voice, visualized.** A calm Home dashboard tracks your words, pace, and day streaks, with a full activity heatmap and a friendly, on-device usage summary — all computed on your Mac.
- 🧩 **Pluggable engines.** Apple's built-in model by default, with optional on-device upgrades — NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper — you can download and switch between, one at a time.

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

| Engine | Languages | Notes |
| --- | --- | --- |
| **Apple Speech** (default) | Varies by macOS | Built in, no download. `SpeechTranscriber` on macOS 26+, on-device `SFSpeechRecognizer` on macOS 14–15 |
| **Parakeet TDT 0.6B V3** | **25** — European only | NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio). Fastest; no CJK |
| **Nemotron 3.5 ASR 0.6B** | **40 locales** incl. CJK, Arabic, Hindi | NVIDIA, via FluidAudio. The multilingual workhorse |
| **Whisper Base** | **99** | OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit). Broadest coverage |

For cleanup, built-in rules (instant, deterministic) are the default; Apple
Intelligence (`FoundationModels`, macOS 26+) is an optional upgrade built into
macOS with nothing to download. See [**docs/LANGUAGES.md**](./docs/LANGUAGES.md)
for the full per-language engine matrix.

Downloadable models are fetched once on demand (no cloud at inference time — your
audio still never leaves the Mac) and run as CoreML on the Apple Neural Engine.
VoiceType automatically falls back to an available engine if your choice can't
run, and always degrades to plain text rather than failing.

> The Parakeet speech model is © NVIDIA, licensed under
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio is
> Apache-2.0. Whisper is OpenAI (MIT); WhisperKit is MIT.

<a name="languages"></a>
## Languages

Most dictation apps are built for English and translated afterwards. VoiceType
treats every language as a first-class case — this is the thing we care most
about getting right.

**33 languages** for dictation · **all 33** with hand-written cleanup rules ·
**16** with a translated interface · **0** that need the cloud.

Arabic · Bulgarian · 简体中文 · Croatian · Czech · Danish · Nederlands ·
English · Estonian · Finnish · Français · Deutsch · Greek · हिन्दी · Hungarian ·
Italiano · 日本語 · 한국어 · Latvian · Lithuanian · Maltese · Norsk · Polski ·
Português · Romanian · Русский · Slovak · Slovenian · Español · Svenska ·
Türkçe · Українська · Tiếng Việt

What "multilingual" actually means here:

- **You pick the language; VoiceType never guesses.** Auto-detection produces
  confident nonsense when it's wrong, so it isn't offered.
- **Engines are matched to your language.** Each speech model declares what it
  supports (Parakeet is European-only; Nemotron covers 40 locales including
  Chinese; Whisper covers 99; Apple's list comes from macOS). Models that can't
  handle your language gray out, and VoiceType switches to one that can.
- **Cleanup knows the language.** Every one of the 33 languages ships a small,
  reviewable "language pack": its filler words (嗯/呃, ähm, euh — never words
  that carry meaning), its punctuation conventions (full-width 。，？ for Chinese
  and Japanese, a narrow no-break space before `!?` in French, `¿` in Spanish,
  the danda `।` in Hindi, `؟` in Arabic), its question heuristics, and its own
  deterministic rules for anything those don't cover. Each has its own eval
  battery — 915 cases in total.
- **The interface is localized** into 16 languages, following your macOS system
  language — independent of your dictation language, so a Japanese interface can
  dictate Portuguese.
- **Curated, not padded.** We could list Whisper's 99 languages tomorrow; we
  offer the ones an engine is genuinely good at, and a test enforces it.

📖 **[Full language matrix, quality tiers, and known gaps →](./docs/LANGUAGES.md)**

Your language missing, or a translation off? Adding a language is deliberately
small — a UI translation needs no Swift at all — see
[docs/LOCALIZATION.md](./docs/LOCALIZATION.md). The machine-authored packs
especially need native-speaker eyes.

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
├── docs/              # LANGUAGES.md (coverage matrix) · LOCALIZATION.md · readme/
├── specs/             # the human's surface — product direction (agent doesn't edit)
└── README.md
```
