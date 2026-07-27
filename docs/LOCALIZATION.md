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
| `casingLocaleIdentifier` | The locale whose casing applies. Set it if `uppercased()` is wrong for you — Turkish needs `"tr_TR"` so `i` becomes `İ`. |
| `terminalMarks` | Characters that already end a sentence, so no period is appended. Override if your orthography ends sentences with something else (`।`, `؟`). |
| `preservesFullWidthMarks` | True when full-width marks （，。？）are correct output for you, so the ASCII repair leaves them alone. Defaults to `usesFullWidthPunctuation`; Korean sets it explicitly. |
| `spokenSymbolWords` | Words that name a symbol out loud, discounted by the faithfulness guard when counting content. Defaults to the English set — replace it with yours. |
| `guardPolicy` | How aggressively the faithfulness guard judges you. Defaults are English-calibrated; languages that pack more meaning per word (Turkish, Korean, Finnish) may need different ratios. |
| `modelLeadInPatterns` | Regexes matching a conversational lead-in the model might emit *in your language* ("Klar, hier ist der bereinigte Text:"). Added to the shared English ones. |

**`rules` — your language's own deterministic fixes**

The fields above answer a fixed set of questions. Everything else your
language needs goes in `rules: [CleanupRule]`, declared in your own pack:

```swift
CleanupRule.regex(
    name: "narrow no-break space before high punctuation",
    stage: .afterPunctuation,
    pattern: "(?<=\\S)([;:!?])",
    template: "\u{202F}$1")
```

A rule is a named, pure `String -> String` fix that runs at one of three
stages — `.early` (raw text, before any shared pass), `.afterPunctuation`
(after spacing and width normalization), `.final` (after capitalization and
terminal punctuation). **Both cleanup paths run all three in the same order**,
so your orthography holds whether the text came from the deterministic floor
or from the model.

Two things to know:

- Rules **sit out terminal dictation** unless you pass `runsInTerminal: true`.
  In a terminal the text is usually a shell command, where a "correction" is
  corruption.
- Pick the stage by what would otherwise undo you. The shared Latin pass
  strips whitespace before `; : ! ?`, so French restores it at
  `.afterPunctuation` — declaring it `.early` would just get it deleted.

This is the pack's escape hatch, and deliberately so: **improving a language
must never require editing shared code**, because that is where languages
collide with each other.

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
| `codeEditorGuidance` | Register when dictating into a code editor. Nil gets a language-neutral instruction. |
| `selfCorrectionRule` | How a speaker of your language changes their mind mid-sentence. Nil falls back to a rule whose example is English — replace it. |
| `fewShot` / `terminalFewShot` | Your own `(spoken, cleaned)` pairs. Empty by default: ship them only once your eval battery shows they help, because the model has been observed echoing example content into its output. Never English's pairs — they invite both leakage and outright translation. |
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
  on your language, that branch belongs in the pack — as data, as a named
  policy the engine already understands, or as a `CleanupRule`.
  `pack.code == "de"` in `RuleBasedCleanup` will not be merged. In practice
  your whole diff should be three paths nobody else touches:
  `Sources/VoiceTypeKit/Languages/<Language>/`,
  `Tests/VoiceTypeKitTests/Languages/<Language>PackTests.swift`, and
  `Scripts/cleanup-eval/cases.<code>.json`. If you believe your language needs
  something the pack genuinely cannot express, say so in the PR rather than
  editing shared code.
- `VoiceTypeKit` stays pure: no resources, no dependencies, everything
  unit-testable.
- Deterministic rules fail conservative: when a rule could corrupt legitimate
  output, it doesn't ship.
- `swift build && swift test` green before you push.

## Status of the shipped languages

**All 33 offered languages now ship a pack**, each with its own tests and its
own eval battery (33 batteries, 915 cases). English and Chinese are the
reference implementations and the most exercised.

Every pack was machine-authored under the house rules on this page —
conservative fillers, no ambiguous spoken punctuation, orthography encoded only
where it is unambiguous — is structurally tested (`PackIntegrityTests`), and
passes its own battery. **None has been reviewed by a native speaker.**

That is the honest status: passing a battery you wrote yourself proves
self-consistency, not correctness. If a language is yours, the highest-value
contribution is a correction — a filler that carries meaning after all, a
convention we got backwards, a case the battery never thought to test. Each is
a small PR touching only that language's three paths.

## Known gaps (help welcome)

- Insights headlines/bullets and the usage summary are generated English prose
  (`InsightsGenerator`, `SummaryPrompt`) — not yet localized.
- Spoken-symbol rendering doesn't yet run over Latin-script runs embedded in
  CJK dictation.
- No pack has been reviewed by a native speaker. Passing a battery you wrote
  yourself proves self-consistency, not correctness.
- `en-GB` has no pack of its own: lookup keys on the primary subtag, so British
  spelling, `pt-PT` and `zh-Hant` cannot differ from their parents until
  resolution becomes script/region aware.
- Several languages independently implemented spoken-symbol rendering as a
  `CleanupRule` because it reaches model output, which `pack.symbols` does not.
  That duplication is a signal the shared engine should apply the pack's
  vocabulary in both paths itself.
- The shared prompt's *fallback* self-correction example is still English
  ("five, no six copies"). A pack that sets `selfCorrectionRule` never sees
  it; one that doesn't, does.
- Latin-script languages all have empty `spokenPunctuation`, because "Punkt" /
  "point" / "punto" are everyday nouns and the table replaces
  unconditionally. A `CleanupRule` that renders them only in unambiguous
  positions is the way in — nobody has written one yet.
- Cleanup engines are not gated by language: the Apple on-device model runs
  for locales Apple Intelligence doesn't support, and only the faithfulness
  guard catches the fallout. `EngineResolver.resolveCleanup` takes no locale.
