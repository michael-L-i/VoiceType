# Localization — add your language to VoiceType

VoiceType aims to be genuinely multilingual, not English-with-subtitles. There
are two independent contribution tracks; do either or both. Chinese (zh) is the
reference implementation for both — copy its shape.

> **What's already supported, and what's missing:**
> [LANGUAGES.md](./LANGUAGES.md) has the full matrix — 33 dictation languages,
> which engine covers which, the cleanup quality tier of each, and an honest
> list of gaps. Check it first to see what your language needs.

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
  `LanguageCoverageTests` enforces this — a locale no downloadable engine
  supports fails the build, so check the matrix in [LANGUAGES.md](./LANGUAGES.md)
  before adding one.
- `Sources/VoiceTypeKit/EngineLanguages.swift` — the per-engine language sets
  are static model-card facts; they rarely change. Apple's list is queried
  from the OS at runtime, so there is usually nothing to do here.

### b. Write a language pack

Each language owns one directory. Copy
`Sources/VoiceTypeKit/Languages/Chinese/` to `Languages/<YourLanguage>/`, fill
it in, and register it in `LanguagePack.all` (`LanguagePack.swift`) — that
registry line is the only shared file you touch.

Every field after `questionSuffixParticles` has a default, so fill in what your
language actually needs and leave the rest alone. Nothing falls back to
English: a field you don't set means the engine skips that behavior or uses a
language-neutral instruction.

**Deterministic behavior**

| Field | What it does |
|---|---|
| `fillers` | Removed deterministically. **House rule: never-content tokens only.** If a word can carry meaning ("like", 那个, Danish "jo", Hungarian "hát"), it does NOT belong here — that's the LLM's job. |
| `spokenPunctuation` | Spoken name → mark, replaced unconditionally (iOS-dictation style). Only include names unambiguous enough for that. |
| `questionPrefixWords` / `questionSuffixParticles` | Deterministic question-mark heuristic. Particles are matched with `hasSuffix`, so multi-character verb endings work. |
| `questionMark` | The mark appended, e.g. `"？"` for CJK, `";"` for Greek. |
| `separatesWordsWithSpaces` | `false` for CJK-style scripts; turns off word-boundary regexes and capitalization. |
| `usesFullWidthPunctuation` / `terminalPeriod` | Writing conventions; full-width packs run `CJKPunctuation.normalize`. |
| `stopwords` | Function words the faithfulness guard skips when probing whether a dictation's opening survived, and that the symbol renderer refuses to join into identifiers. Leaving it empty only makes both checks more conservative. |
| `symbols` | A `SpokenSymbolVocabulary` — your language's words for "dot", "underscore", "open paren", plus the file extensions and TLDs worth joining. Opting in enables `main.py`-style rendering in the zero-latency rules path. Omit it if your trigger words are everyday nouns (German "Punkt", Chinese 点); that ambiguity is what the LLM pass is for. |
| `capitalizedStandalonePronoun` | Only for orthographies with a one-letter capitalized pronoun. English "i" → "I"; almost certainly nil for you. |

**LLM prompt** — `prompt: LanguagePromptGuidance`

The instruction frame stays English and shared: a small on-device model follows
English instructions more reliably, and "don't summarize, don't answer the
dictation, don't reformat into bullets" is the same job in every language. What
differs is the substance, and that's what you supply.

| Field | What it does |
|---|---|
| `fillerExamples` | Appended to the generic filler instruction. Your hesitation sounds, not English's. |
| `capitalizationRule` | Replaces the generic rule wholesale — German capitalizes every noun, Turkish has a dotted/dotless I, Devanagari has no case. |
| `codeRendering` | How your speakers dictate symbols and file names. Omitted entirely when nil, which is correct: teaching a German transcript to render the English word "dot" only produced false joins. |
| `terminalGuidance` | Spoken flags and paths when dictating into a terminal. |
| `usesFewShotExamples` | Off by default. Turn it on only once your eval battery shows examples help — the model has been observed echoing example content into its output. |
| `addendum` | Free-form extra rules (full-width punctuation, ¿…?). Keep minimal; prompt content leaks. |

Document your judgment calls (what you deliberately did NOT map, and why) in
the file, the way the Chinese pack does. Reviewers read that comment first.

### c. Tests

Add `Tests/VoiceTypeKitTests/Languages/<YourLanguage>PackTests.swift` — your
own file, never the shared one, so two languages in flight can't collide.
Cover: filler removal, spoken punctuation + idempotence, terminal punctuation,
embedded English/identifiers surviving untouched, and the terminal app category
staying command-safe. `swift test` must be green.

### d. Eval cases

Create `Scripts/cleanup-eval/cases.<code>.json` with **at least 10 cases**,
each carrying `"locale"` (see `cases.zh.json`). Cover: spoken punctuation
(exact), fillers removed + ambiguous words retained, punctuation conventions,
question heuristic, embedded English/file names, one long anti-translation /
anti-summarization ramble, and one terminal-category command. Then run:

```sh
swift run CleanupEval Scripts/cleanup-eval/cases.<code>.json --engine rules   # deterministic gates — must pass
swift run CleanupEval Scripts/cleanup-eval/cases.json --engine rules          # English must stay at its baseline (35/38)
swift run CleanupEval Scripts/cleanup-eval/cases.zh.json --engine rules       # Chinese must stay at 20/20

# Optional, and not parallel-safe — it drives the single on-device model and
# needs Apple Intelligence. Report scores in the PR if you run it.
swift run CleanupEval Scripts/cleanup-eval/cases.<code>.json --engine model
```

Note for the model run: eval reports the raw model output. In production a
`guardTripped: true` result falls back to the rules floor, so judge those rows
by what the rules engine produces.

### House rules

- **One language, three files**: `Languages/<Language>/<Language>Pack.swift`,
  `Tests/VoiceTypeKitTests/Languages/<Language>PackTests.swift`,
  `Scripts/cleanup-eval/cases.<code>.json`. The only shared line you touch is
  the `LanguagePack.all` registry.
- **No language special-cases in shared code.** If the engine needs to branch
  on your language, that branch belongs in the pack as data or as a named
  policy the engine already understands. `pack.code == "de"` in
  `RuleBasedCleanup` will not be merged.
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
- Spoken-symbol rendering doesn't yet run over Latin-script runs embedded in
  CJK dictation.
- English is still the only language with a `symbols` vocabulary, a
  `codeRendering` prompt section, or `terminalGuidance`. Adding yours is the
  single biggest quality win available for a language today.
- 18 of the 34 offered dictation locales have no pack at all and fall back to
  `.neutral`, where "remove fillers" does nothing: ar, bg, cs, da, el, et, fi,
  hi, hr, hu, lt, lv, mt, nb, ro, sk, sl, plus en-GB spelling. Arabic (RTL,
  `؟ ،`) and Greek (`;` as question mark) need engine support beyond a pack.
- The self-correction example in the shared prompt ("five, no six copies") is
  still English; a language can override it via `addendum` until it's lifted
  into `LanguagePromptGuidance`.
- `RuleBasedCleanup.capitalizeSentences` uppercases with Swift's
  locale-independent `uppercased()`, so Turkish `istanbul` becomes `Istanbul`
  rather than `İstanbul`. Fixing it needs a casing policy on the pack.
