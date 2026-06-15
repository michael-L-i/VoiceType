# CLAUDE.md

Guidance for Claude Code working in this repository. These rules override default
behavior — follow them exactly.

## What VoiceType is

VoiceType is an open-source **Wispr Flow clone**: a fast, private voice-dictation
app. You hold a global hotkey, speak, and your words are transcribed and typed
into whatever app is focused — with light AI cleanup (punctuation, filler-word
removal, formatting). Latency and privacy are the product, not afterthoughts.

**North star:** _Speak anywhere, get clean text instantly, with your audio never
leaving your control unless you opt in._

## Where this repo sits

This is a **standalone product repo**. It lives as a sibling inside the
`solo_agent_systems/` container alongside the `agent-repo-os/` framework, but it
has its own `.git` and its own GitHub remote — it is **not** part of a monorepo.

```
solo_agent_systems/          ← plain container folder (not a repo)
├── agent-repo-os/           ← the @aros/* framework ("the OS")
└── VoiceType/               ← THIS repo (its own .git + remote)
```

- During local dev, the agent framework is consumed via `link:` deps pointing at
  `../agent-repo-os/packages/*`. In production those `@aros/*` packages are
  installed from npm like any normal dependency. Nothing else changes.
- Human "taste" lives in `specs/` (constitution, taste, roadmap). Treat it as the
  source of truth for product direction — see **specs/** below.

## Autonomous workflow

You have full autonomy to branch, commit, push, and open PRs. Don't ask
permission for those — just do it.

- **Branch, never touch `main` directly.** Always work on a feature branch.
- **Commit freely and incrementally.** One logical change per commit. Reasonably
  sized — prefer several small, reviewable commits over one large one. Use
  conventional messages (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`).
- **Always commit completed user-requested changes.** Do not leave working-tree
  changes uncommitted at the end of a task unless the user explicitly asks you
  not to commit or the change is not yet working.
- **Use incremental commits for longer tasks.** Commit after each verified,
  coherent milestone so progress is recoverable and reviewable.
- **Push with upstream tracking** (`git push -u origin <branch>`).
- **Open a PR to `main`** after pushing, with a clear summary of intent + changes.
- **Do NOT merge your own PRs** — the human reviews and merges on GitHub.

Commit or push only when there is real, working progress — not partial or broken
states. Verify (type-check / build / run) before you push.

Do not automatically rebuild and relaunch the local app after every code change
or commit. When the user explicitly asks to update the running app, rebuild the
existing local app bundle in place and relaunch that same bundle. Preserve the
same bundle ID/path/signing setup; do not delete app permissions, reset TCC, move
the app bundle, or use a launch path that would force the user to grant macOS
permissions again.

## specs/ — the human's surface (do not edit yourself)

Product direction is set by a human editing `specs/`. You read it; you don't
write it (the one exception is automated write-back from an approved escalation).

- `specs/CONSTITUTION.md` — north star, principles, non-goals, guardrails. The
  agent reconstructs every accept/reject decision from this file.
- `specs/TASTE.md` — judgment by example (good/bad patterns). Grows over time.
- `specs/ROADMAP.md` — Now / Next / Later. You groom issues against this.

When a request touches direction, public API, or UX in a way `specs/` doesn't
settle: **ask one sharp question, then stop.** Never guess on taste.

## Architecture (locked — native Swift)

> **Shell decision (human-approved, 2026-06-08):** native **Swift 6 / SwiftUI**,
> overriding the earlier Electron proposal. Rationale: Mac-only + latency-first +
> direct Apple Intelligence access (on-device `SpeechTranscriber` and
> `FoundationModels`), which Electron can't reach without a Swift sidecar anyway.
> `specs/ROADMAP.md` and `specs/CONSTITUTION.md` still mention Electron/TS — those
> are the human's surface, so update them there when convenient.

Keep it simple; don't over-engineer.

- **Shell:** SwiftPM menu-bar app (no Dock icon). `VoiceTypeKit` is the pure,
  dependency-free, unit-tested core (protocols, models, pipeline, rule cleanup,
  resolver); the `VoiceType` executable holds the app, system engines, and UI.
  Build the bundle with `Scripts/build-app.sh`.
- **Global hotkey + injection:** `HotkeyMonitor` (global `flagsChanged`,
  push-to-talk, default Right Option) → `PasteboardInjector` (⌘V + clipboard
  restore). Both gated on Accessibility consent.
- **Audio capture:** `AudioCaptureService` (AVAudioEngine, mono 16 kHz).
- **Transcription:** pluggable `TranscriptionEngine`. Default Apple on-device
  `SpeechTranscriber`; `whisper.cpp` local fallback; opt-in Groq cloud.
- **Cleanup pass:** pluggable `CleanupEngine`. Default Apple `FoundationModels`
  on-device; deterministic `RuleBasedCleanup` floor; opt-in Groq cloud. Always
  degrades to raw text rather than failing.
- **Selection policy:** `EngineResolver` (in Kit) enforces consent + availability
  fallback; `EngineFactory` (in app) maps kinds → concrete engines.

Privacy invariant: **audio and transcripts stay local by default.** Any path that
sends data off-device is opt-in, clearly labeled, and gated behind explicit
consent (the master "Enable cloud" toggle).

## Code standards

- Swift 6 everywhere (language mode v5 for now). Match existing patterns before
  introducing new ones. Keep `VoiceTypeKit` pure and framework-free so it stays
  testable.
- Ship the smallest thing that is genuinely good. Opinionated over configurable —
  a setting is a decision you failed to make.
- Keep solutions simple and focused. No speculative abstraction.
- Build (`swift build`) and test (`swift test`) before pushing.

## Safety

- Only ever act inside **this** repo. Never email, post, or contact anyone
  externally on the user's behalf without explicit approval.
- Any irreversible or outward-facing action requires human approval first.
- Prefer `trash` over `rm`. Don't run destructive commands without asking.
- Never exfiltrate private data — especially user audio or transcripts.
- When in doubt, ask one question and wait.

## Memory & write-it-down

You start each session fresh. If something is worth remembering — a decision, a
gotcha, a lesson from a mistake — **write it to a file**, don't keep a "mental
note." Update this CLAUDE.md, the relevant doc, or `specs/` (via the human) so
future sessions don't relearn it.
