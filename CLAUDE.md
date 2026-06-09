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
- **Push with upstream tracking** (`git push -u origin <branch>`).
- **Open a PR to `main`** after pushing, with a clear summary of intent + changes.
- **Do NOT merge your own PRs** — the human reviews and merges on GitHub.
- End commit messages with the `Co-Authored-By: Claude` trailer when committing
  on the user's behalf.

Commit or push only when there is real, working progress — not partial or broken
states. Verify (type-check / build / run) before you push.

## specs/ — the human's surface (do not edit yourself)

Product direction is set by a human editing `specs/`. You read it; you don't
write it (the one exception is automated write-back from an approved escalation).

- `specs/CONSTITUTION.md` — north star, principles, non-goals, guardrails. The
  agent reconstructs every accept/reject decision from this file.
- `specs/TASTE.md` — judgment by example (good/bad patterns). Grows over time.
- `specs/ROADMAP.md` — Now / Next / Later. You groom issues against this.

When a request touches direction, public API, or UX in a way `specs/` doesn't
settle: **ask one sharp question, then stop.** Never guess on taste.

## Architecture (starting proposal — refine in specs/ROADMAP.md)

This is the intended shape, not yet built. Keep it simple; don't over-engineer.

- **Shell:** Electron + TypeScript + React (macOS first, Windows later).
- **Global hotkey + injection:** capture a system-wide push-to-talk key; inject
  resulting text into the focused app via the accessibility/paste path.
- **Audio capture:** stream mic audio while the key is held.
- **Transcription:** pluggable. Default to a local model (e.g. `whisper.cpp`) for
  the privacy promise; allow an opt-in cloud provider for speed/quality.
- **Cleanup pass:** a small LLM/formatting step for punctuation, casing, and
  filler removal. Must be fast and degrade gracefully if unavailable.

Privacy invariant: **audio and transcripts stay local by default.** Any path that
sends data off-device is opt-in, clearly labeled, and gated behind explicit
consent.

## Code standards

- TypeScript everywhere. Match existing patterns before introducing new ones.
- Ship the smallest thing that is genuinely good. Opinionated over configurable —
  a setting is a decision you failed to make.
- Keep solutions simple and focused. No speculative abstraction.
- Type-check (`npx tsc --noEmit`) and lint before pushing.

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
