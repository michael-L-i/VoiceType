# Localization — add your language to VoiceType

VoiceType aims to be genuinely multilingual, not English-with-subtitles. There
are two independent contribution tracks; do either or both. Chinese (zh) is the
reference implementation for both — copy its shape.

## Track 1 — Translate the UI (no Swift required)

The UI follows the macOS system language (per-app override: System Settings →
General → Language & Region → Applications → VoiceType). English text is the
key; anything untranslated falls back to English.

1. Copy `Sources/VoiceType/Resources/en.lproj/Localizable.strings` to
   `Sources/VoiceType/Resources/<code>.lproj/Localizable.strings`
   (`<code>` is the BCP-47 UI language, e.g. `fr`, `zh-Hant`).
2. Translate the **values only** — keys stay exactly as they are. Keep
   `%@` / `%lld` placeholders; use `%1$@`-style positions if your language
   reorders them.
3. Add your code to `CFBundleLocalizations` in `Resources/Info.plist`.
4. Run `Scripts/check-l10n.sh` — it fails if your file's key set drifts from
   English.
5. Build (`Scripts/build-app.sh`), switch the app's language in System
   Settings, and screenshot Home / Settings / Models / Setup for the PR.

If your language needs plural forms (English text like "%lld words"), add a
`Localizable.stringsdict` in your `.lproj` — that's the standard drop-in;
Chinese doesn't need one, so there's no example yet.

## Track 2 — Make dictation great in your language

### a. Check the language picker and engine matrix

- `Sources/VoiceTypeKit/DictationLanguage.swift` — add your locale to `all` if
  it's missing (curated: at least one engine must be genuinely good at it).
- `Sources/VoiceTypeKit/EngineLanguages.swift` — the per-engine language sets
  are static model-card facts; they rarely change. Apple's list is queried
  from the OS at runtime, so there is usually nothing to do here.

### b. Write a language pack

Copy `Sources/VoiceTypeKit/Languages/LanguagePack+Chinese.swift` to
`LanguagePack+<YourLanguage>.swift`, fill it in, and register it in
`LanguagePack.all` (`LanguagePack.swift`). The fields:

| Field | What it does |
|---|---|
| `fillers` | Removed deterministically. **House rule: never-content tokens only.** If a word can carry meaning ("like", 那个), it does NOT belong here — that's the LLM's job. |
| `spokenPunctuation` | Spoken name → mark, replaced unconditionally (iOS-dictation style). Only include names unambiguous enough for that. |
| `questionPrefixWords` / `questionSuffixParticles` | Deterministic question-mark heuristic (English probes the first word, Chinese the final particle). |
| `separatesWordsWithSpaces` | `false` for CJK-style scripts; turns off word-boundary regexes and capitalization. |
| `usesFullWidthPunctuation` / `terminalPeriod` | Writing conventions; full-width packs run `CJKPunctuation.normalize`. |
| `promptAddendum` | A few extra lines for the LLM cleanup prompt. Keep it minimal — few-shot examples leak into output. |

Document your judgment calls (what you deliberately did NOT map, and why) in
the file, the way the Chinese pack does.

### c. Tests

Add a suite to `Tests/VoiceTypeKitTests/LanguagePackTests.swift` (or a new
file) covering: filler removal, spoken punctuation + idempotence, terminal
punctuation, embedded English/identifiers surviving untouched, and the
terminal app category staying command-safe. `swift test` must be green.

### d. Eval cases

Create `Scripts/cleanup-eval/cases.<code>.json` with **at least 10 cases**,
each carrying `"locale"` (see `cases.zh.json`). Cover: spoken punctuation
(exact), fillers removed + ambiguous words retained, punctuation conventions,
question heuristic, embedded English/file names, one long anti-translation /
anti-summarization ramble, and one terminal-category command. Then run:

```sh
swift run CleanupEval Scripts/cleanup-eval/cases.<code>.json --engine rules   # deterministic gates — must pass
swift run CleanupEval Scripts/cleanup-eval/cases.<code>.json --engine model   # needs Apple Intelligence; report scores in the PR
swift run CleanupEval Scripts/cleanup-eval/cases.json --engine rules          # English must stay at its baseline (35/38)
```

Note for the model run: eval reports the raw model output. In production a
`guardTripped: true` result falls back to the rules floor, so judge those rows
by what the rules engine produces.

### House rules

- `VoiceTypeKit` stays pure: no resources, no dependencies, everything
  unit-testable.
- Deterministic rules fail conservative: when a rule could corrupt legitimate
  output, it doesn't ship.
- `swift build && swift test` green before you push.

## Status of the shipped languages

Chinese (zh) is the reference implementation, tested against its own eval
battery. The other non-English languages (de, es, fr, it, ja, ko, nl, pl,
pt-BR, ru, sv, tr, uk, vi) were machine-authored following the house rules —
conservative fillers, no ambiguous spoken punctuation — and reviewed
structurally (`PackIntegrityTests`), but they have **not** been reviewed by
native speakers and ship without per-language eval batteries. If that's your
language: corrections to the UI translation, richer (still never-content)
fillers, and a `cases.<code>.json` battery are the most valuable
contributions you can make, and each is a small PR.

## Known gaps (help welcome)

- Insights headlines/bullets and the usage summary are generated English prose
  (`InsightsGenerator`, `SummaryPrompt`) — not yet localized.
- `SpokenSymbols` (English spoken-symbol pipeline: "main dot pie" → main.py)
  doesn't yet run over Latin-script runs embedded in CJK dictation.
