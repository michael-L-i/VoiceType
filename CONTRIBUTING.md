# Contributing to VoiceType

Thanks for taking an interest in VoiceType. It is a privacy-first macOS
dictation app: audio and transcripts stay on-device by default. Contributions
that preserve that principle and make dictation faster, more reliable, or more
pleasant are especially welcome.

## Before you start

- For a small documentation fix or focused bug fix, open a pull request.
- For a substantial feature, engine change, product-direction question, or UX
  redesign, start a GitHub Discussion or contact the maintainer first. This
  helps us agree on scope before you spend time implementing it.
- Please keep one concern per pull request. Separate refactors from behaviour
  changes whenever practical.

## Development setup

VoiceType requires macOS 26 or newer, Apple Silicon, and Xcode 26 or newer.

```bash
git clone https://github.com/michael-L-i/VoiceType.git
cd VoiceType
swift test
./Scripts/build-app.sh
open VoiceType.app
```

Swift Package Manager resolves the dependencies automatically. Local build
artifacts, audio files, downloaded models, and environment files are ignored
and must not be committed.

## Making a change

1. Create a branch from the current `main`, using a descriptive name such as
   `fix/hotkey-focus` or `docs/setup-clarification`.
2. Follow the existing code structure and keep `VoiceTypeKit` pure and
   dependency-free.
3. Add or update focused tests for changes to `VoiceTypeKit` behaviour.
4. Run the relevant checks before opening a pull request:

   ```bash
   swift build
   swift test
   ```

5. Open a pull request against `main` with a clear summary, test results, and
   any macOS version or permission assumptions.

## Pull request expectations

- Use a concise conventional-commit style title, such as `fix: restore
  pasteboard contents` or `docs: clarify local build setup`.
- Do not include secrets, API keys, transcripts, or audio samples containing
  private content.
- Do not add cloud processing, telemetry, or network transmission of audio or
  transcripts without explicit discussion and opt-in design.
- Update user-facing documentation when behaviour or setup changes.
- Be patient and respectful during review. Maintainer capacity may vary.

## License

By submitting a contribution, you agree that your contribution is licensed
under the repository's [MIT License](./LICENSE).
