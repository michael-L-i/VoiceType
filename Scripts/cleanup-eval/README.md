# Cleanup eval harness

Runs dictation transcripts through the **production cleanup path**. The default
engine is the real on-device FoundationModels model with `CleanupPrompt`, then
`CleanupSanitizer` → `CleanupGuard` → `CleanupPolish`, exactly as
`FoundationModelsCleanupEngine` ships it (needs macOS 26+ with Apple
Intelligence enabled). `--engine rules` runs the deterministic
`RuleBasedCleanup` path instead — no model needed — so both engines are
benchmarked against the same battery.

```sh
swift run CleanupEval Scripts/cleanup-eval/cases.json                 # full battery (model)
swift run CleanupEval Scripts/cleanup-eval/cases.json --runs 2        # variance check
swift run CleanupEval Scripts/cleanup-eval/cases.json --id dot-pie
swift run CleanupEval Scripts/cleanup-eval/cases.json --engine rules  # deterministic floor
```

As of 2026-07 the rule engine scores **35/38** on the battery (~0 ms); its three
failures — both self-correction cases and the camelCase directive — are the
same accepted limitations listed below for the model. Re-run `--engine rules`
whenever `RuleBasedCleanup`/`SpokenSymbols` change; those paths are also unit
tested, so the battery is a cross-check, not the only gate.

One JSON line per case-run: the cleaned output, pass/fail against the case's
`exact` / `mustContain` / `mustNotContain` expectations, and deterministic
faithfulness metrics (`retention`, `orderScore`, `addedWords`, `guardTripped`).

## How to read `guardTripped: true`

A trip is **not** a shipping failure: production discards the model output and
falls back to deterministic `RuleBasedCleanup`, so the user gets safe (if
plainer) text. A case scoring `ok: false` *with* a trip means the seatbelt
worked; `ok: false` *without* a trip is text that actually reaches the user.

## Known accepted limitations (as of the 6-battery eval, 2026-07)

- **Numeric self-correction** ("five, no six copies") — the model keeps the
  wrong value or leaves the correction unresolved. Three prompt attempts did
  not move it; not guard-visible (no length change). The unresolved variant
  loses no information.
- **camelCase directive** ("camel case get user name" → getUserName) — the
  model snake_cases instead. The fully-fused garbage variant trips the guard;
  the spaced variant ships as snake_case. The rule engine leaves the words
  as spoken (the identifier's end is not deterministically knowable).
- **Terminal-prose fillers** — dictating prose into a terminal occasionally
  keeps a comma-wrapped "um" (filler rules are prompt-side only there).
- **Numeric/name self-correction in the rule engine** — "five, no six" needs
  meaning, not rules; the rule path keeps both. Unresolved loses no information.

## Hard-won lessons (don't relearn these)

- **Few-shot examples leak.** Adding realistic example pairs made the model
  regurgitate one verbatim as output and bleed example words ("auth token")
  into unrelated dictations. Keep the example set small; prefer short absolute
  rules; never add an example that looks like a plausible real dictation
  answer to a different input.
- **Prompt instructions don't fix mechanical details.** Capitalization,
  question marks, and `_underscore_` repair were inert as prompt rules and
  trivial as deterministic post-passes (`CleanupPolish`).
- **The guard must never discard good output.** Catching garbage is
  best-effort; a false trip degrades a perfect result to rule-based text.
