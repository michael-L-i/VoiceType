# Language support

VoiceType dictates in **33 languages** and ships its interface in **16**.
This page is the full picture: what's supported, by which engine, how well —
and where the gaps are.

Everything below runs **on-device**. Language coverage never costs you privacy:
there is no "send it to the cloud for the hard languages" path.

- **34 locales** in the language picker (33 languages; English has US and UK).
- **All 33 languages** have their own cleanup [language pack](#cleanup-quality-tiers)
  and their own eval battery — 915 test cases in total.
- **16 languages** have a translated interface.
- **Zero** languages require a network round-trip.

## How we choose what to offer

The picker is **curated, not exhaustive**. Whisper's tokenizer alone lists 99
languages, and we could offer all of them tomorrow — but "the model emits
tokens" is not the same as "dictation is good here". A language ships when at
least one on-device engine is genuinely good at it, which is enforced by a test
([`LanguageCoverageTests`](../Tests/VoiceTypeKitTests/LanguageCoverageTests.swift)):
every offered language must be transcribable by a downloadable engine, not just
by Apple's (whose coverage varies by macOS version).

**We would rather support 33 languages well than 99 badly.** If your language is
missing and an engine handles it, that is a bug — [tell us](#missing-your-language).

## Dictation matrix

Which on-device engine can transcribe which language.

**●** supported · **·** not supported · **Apple** is queried from macOS at
runtime, so it varies by OS version and installed assets.
[Parakeet](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) and
[Nemotron](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b) sets
are model-card facts; Whisper's is its tokenizer list.

| Language | Locale | Parakeet | Nemotron | Whisper | Cleanup pack | UI |
| --- | --- | :-: | :-: | :-: | :-: | :-: |
| Arabic | `ar-SA` | · | ● | ● | ✅ | |
| Bulgarian | `bg-BG` | ● | ● | ● | ✅ | |
| Chinese (Simplified) | `zh-CN` | · | ● | ● | ✅ ref | ✅ |
| Croatian | `hr-HR` | ● | ● | ● | ✅ | |
| Czech | `cs-CZ` | ● | ● | ● | ✅ | |
| Danish | `da-DK` | ● | ● | ● | ✅ | |
| Dutch | `nl-NL` | ● | ● | ● | ✅ | ✅ |
| English | `en-US` `en-GB` | ● | ● | ● | ✅ ref | ✅ |
| Estonian | `et-EE` | ● | ● | ● | ✅ | |
| Finnish | `fi-FI` | ● | ● | ● | ✅ | |
| French | `fr-FR` | ● | ● | ● | ✅ | ✅ |
| German | `de-DE` | ● | ● | ● | ✅ | ✅ |
| Greek | `el-GR` | ● | · | ● | ✅ | |
| Hindi | `hi-IN` | · | ● | ● | ✅ | |
| Hungarian | `hu-HU` | ● | ● | ● | ✅ | |
| Italian | `it-IT` | ● | ● | ● | ✅ | ✅ |
| Japanese | `ja-JP` | · | ● | ● | ✅ | ✅ |
| Korean | `ko-KR` | · | ● | ● | ✅ | ✅ |
| Latvian | `lv-LV` | ● | · | ● | ✅ | |
| Lithuanian | `lt-LT` | ● | · | ● | ✅ | |
| Maltese | `mt-MT` | ● | · | ● | ✅ | |
| Norwegian Bokmål | `nb-NO` | · | ● | ● | ✅ | |
| Polish | `pl-PL` | ● | ● | ● | ✅ | ✅ |
| Portuguese (Brazil) | `pt-BR` | ● | ● | ● | ✅ | ✅ |
| Romanian | `ro-RO` | ● | ● | ● | ✅ | |
| Russian | `ru-RU` | ● | ● | ● | ✅ | ✅ |
| Slovak | `sk-SK` | ● | ● | ● | ✅ | |
| Slovenian | `sl-SI` | ● | · | ● | ✅ | |
| Spanish | `es-ES` | ● | ● | ● | ✅ | ✅ |
| Swedish | `sv-SE` | ● | ● | ● | ✅ | ✅ |
| Turkish | `tr-TR` | · | ● | ● | ✅ | ✅ |
| Ukrainian | `uk-UA` | ● | ● | ● | ✅ | ✅ |
| Vietnamese | `vi-VN` | · | ● | ● | ✅ | ✅ |

Reading the matrix:

- **Parakeet (25 languages)** is European-only — fastest, no CJK, no Arabic/Hindi.
- **Nemotron (28 of our languages)** is the multilingual workhorse: CJK, Arabic,
  Hindi, Vietnamese, Turkish. It excludes the languages its own model card calls
  adaptation-only (Greek, Lithuanian, Latvian, Maltese, Slovenian) rather than
  ship silent empty transcripts.
- **Whisper (99 languages)** is the broad floor — it covers every language we
  offer, which a test enforces.
- **Apple Speech** is the built-in default and needs no download.

You never have to read this table to use the app: pick your language and
VoiceType grays out the models that can't handle it and falls back to one that
can ([`EngineResolver`](../Sources/VoiceTypeKit/EngineResolver.swift)). The
engines' language sets don't nest cleanly, so the picker offers the **union**
rather than intersecting everyone down to the smallest common set.

> **Nemotron speaks strictly.** It treats the selected language as a hard filter:
> speak French with Chinese selected and you get an empty result ("Didn't catch
> that"), not a wrong-language guess. Pick the language you're actually speaking.

## Cleanup quality tiers

Transcription is half the job. The cleanup pass — punctuation, capitalization,
filler removal — has to know your language's conventions, or "multilingual"
means "English rules applied to your words".

**Every one of the 33 languages ships a full language pack.** There is no
"neutral cleanup" tier any more — no language falls back to English's rules, and
none falls back to nothing. Each ships a reviewable
[`LanguagePack`](../Sources/VoiceTypeKit/Languages/) declaring:

- its **filler words** (嗯/呃, ähm, euh) — never-content tokens only;
- its **spoken punctuation** (句号 → 。, 読点 → 、) rendered as marks;
- its **writing conventions** — full-width 。，？ for Chinese and Japanese, the
  narrow no-break space before `!?;` and non-breaking space before `:` in
  French, `¿` and `¡` in Spanish, the danda `।` in Hindi, `؟ ، ؛` in Arabic,
  `;` as Greek's question mark, Turkish's dotted/dotless `İ`/`I`;
- its **question heuristics** — English probes the first word, Chinese the final
  particle (吗), Korean the verb ending;
- its own **deterministic rules** ([`CleanupRule`](../Sources/VoiceTypeKit/CleanupRule.swift))
  for anything the fields above can't express, run in both the zero-latency path
  and the repair applied to model output;
- its own **LLM prompt guidance** — hesitations, capitalization rule, spoken-code
  triggers, self-correction phrasing, in that language rather than English's.

Every pack ships **its own eval battery** — 33 batteries, 915 cases total,
runnable with `swift run CleanupEval Scripts/cleanup-eval/cases.<code>.json
--engine rules`.

**What this does and does not mean.** The packs are machine-authored under
conservative house rules, structurally tested (`PackIntegrityTests`), and each
passes its own battery. They have **not been reviewed by native speakers**. If a
language is yours, the highest-value contribution is now a *correction* rather
than a from-scratch pack: a filler that shouldn't be there, a convention we got
wrong, a case the battery is missing. See
[LOCALIZATION.md](./LOCALIZATION.md#status-of-the-shipped-languages).

## Interface languages

The app itself is translated into 16 languages and follows your macOS system
language — per-app override in **System Settings → General → Language & Region →
Applications** works too. Untranslated strings fall back to English, so a partial
translation is still a useful contribution.

English · 简体中文 · Deutsch · Español · Français · Italiano · 日本語 · 한국어 ·
Nederlands · Polski · Português (BR) · Русский · Svenska · Türkçe · Українська ·
Tiếng Việt

The UI language and the dictation language are **independent** — a Japanese
interface can dictate Portuguese.

## Known gaps

Honest list of where multilingual support is still thin:

- **No pack has been reviewed by a native speaker.** All 33 are machine-authored
  under conservative house rules and pass their own batteries, which is not the
  same as being right. This is the single biggest gap.
- **`SpokenSymbols`** doesn't yet run over Latin-script runs embedded in CJK
  dictation.
- **Cleanup engines are not gated by language.** The Apple on-device model runs
  for locales Apple Intelligence doesn't support, and only the faithfulness
  guard catches the fallout — `EngineResolver.resolveCleanup` takes no locale.
- **A `CleanupRule` receives no `CleanupOptions`**, so a pack rule cannot honor
  "capitalization off" / "punctuation off". Fine for orthography that is always
  correct; a language whose rule is genuinely optional cannot express that.
- **`en-GB` rides on English's pack.** Pack lookup keys on the primary subtag,
  so British spelling, `pt-PT`, and `zh-Hant` cannot differ from their parents
  until lookup becomes script/region aware.
- **Insights headlines and the usage summary** (`InsightsGenerator`,
  `SummaryPrompt`) are generated English prose, not yet localized.
- **No right-to-left UI work.** Arabic dictation works; an Arabic *interface*
  would need RTL layout review that hasn't happened.
- **Whisper's other 66 languages** are deliberately not offered — no second
  engine and no pack means we can't vouch for the experience yet.

## Missing your language?

Adding one is deliberately small, and the two tracks are independent:

- **Translate the UI** — no Swift at all, just one `.strings` file.
- **Correct your language's pack** — every language already has one, so the work
  is now fixing what's wrong rather than starting from nothing: a filler that
  isn't really a filler, a convention we got backwards, a missing eval case.

Both are walked through step by step in [LOCALIZATION.md](./LOCALIZATION.md).
Corrections are the most valuable contribution available — the packs are
machine-authored and have never had native-speaker eyes on them.
