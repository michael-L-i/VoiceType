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
- Do not automatically rebuild and relaunch the local app after every code
  change or commit. When the user explicitly asks to update the running app,
  rebuild the existing local app bundle in place and relaunch that same bundle
  using the flow below.

## Relaunching local app builds

When the user asks to update/relaunch the running macOS app, use this
path-preserving flow:

1. Check what app bundle is currently running:
   `pgrep -afil VoiceType || true`
2. Quit the running app by bundle ID:
   `osascript -e 'tell application id "com.voicetype.app" to quit' || true`
3. Wait until no `VoiceType` process remains before replacing or relaunching it.
4. Rebuild the repo bundle:
   `Scripts/build-app.sh release`
5. If the user was running `/Applications/VoiceType.app`, update that same
   bundle in place:
   `ditto VoiceType.app /Applications/VoiceType.app`
6. Relaunch the same bundle path the user was already using, usually:
   `open /Applications/VoiceType.app`
7. Verify the relaunched process:
   `pgrep -afil VoiceType || true`

Do not launch a different copy of the app than the one the user was running;
changing bundle paths can trigger duplicate instances or fresh macOS permission
prompts. Preserve the same bundle ID/path/signing setup; do not delete app
permissions, reset TCC, move the app bundle, or use a launch path that would
force the user to grant macOS permissions again.

## Project Notes

- VoiceType is a native Swift/SwiftUI macOS menu-bar dictation app.
- Keep `VoiceTypeKit` pure and dependency-free.
- Audio and transcripts stay local by default. Any cloud path must be explicit,
  opt-in, and clearly labeled.
- Match existing patterns and keep changes focused.

For Claude-specific context, also read `CLAUDE.md`.
