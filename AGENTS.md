# AGENTS.md

Guidance for coding agents working in this repository.

## Workflow

- Work on a feature branch; never make changes directly on `main`.
- Always commit completed user-requested changes before ending the task, unless
  the user explicitly asks you not to commit or the change is not working yet.
- For longer tasks, make incremental commits after each verified, coherent
  milestone.
- Use conventional commit messages such as `feat:`, `fix:`, `docs:`, or
  `chore:`.
- Verify changes with the appropriate build or test command before committing.
- After any user-prompted app change, rebuild and relaunch the local app so the
  user gets the latest updated version.

## Project Notes

- VoiceType is a native Swift/SwiftUI macOS menu-bar dictation app.
- Keep `VoiceTypeKit` pure and dependency-free.
- Audio and transcripts stay local by default. Any cloud path must be explicit,
  opt-in, and clearly labeled.
- Match existing patterns and keep changes focused.

For Claude-specific context, also read `CLAUDE.md`.
