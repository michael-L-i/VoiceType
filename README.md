# VoiceType

A fast, private, open-source voice-dictation app — a Wispr Flow clone.

Hold a global hotkey, speak, and your words are transcribed and typed into
whatever app is focused, with light AI cleanup (punctuation, casing, filler
removal). **Latency and privacy are the product:** audio and transcripts stay
on-device by default; any cloud path is opt-in and clearly labeled.

> **North star:** Speak anywhere, get clean text instantly, with your audio never
> leaving your control unless you opt in.

## Status

Early. This repo is being scaffolded — see `specs/ROADMAP.md` for what's next.

## How this repo is run

VoiceType is a standalone product repo run day-to-day by an agent (the **outer
loop**: triage → review → merge/escalate), with a human supplying **taste** by
editing `specs/`. It links the [`@aros/*`](../agent-repo-os) framework during
local dev. See [`CLAUDE.md`](./CLAUDE.md) for the operating rules.

## Architecture (proposed)

Electron + TypeScript + React shell · global push-to-talk hotkey · mic capture ·
pluggable transcription (local `whisper.cpp` by default, opt-in cloud) · fast
formatting cleanup pass. Details live in `CLAUDE.md` and evolve via `specs/`.

## Repo layout

```
VoiceType/
├── CLAUDE.md     # operating rules for the agent
├── specs/        # the human's surface — product direction (do not let the agent edit)
│   ├── CONSTITUTION.md
│   ├── TASTE.md
│   └── ROADMAP.md
└── README.md
```
