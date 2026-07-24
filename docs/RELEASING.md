# Releasing VoiceType

VoiceType ships two install paths per release:

- **`VoiceType.dmg`** — the human download (drag-to-Applications).
- **`VoiceType.zip` + `appcast.xml`** — the [Sparkle](https://sparkle-project.org)
  auto-update payload and its signed feed. Installed copies poll the appcast and
  update themselves in place.

## One-time setup: the signing key

### Apple Developer ID + notarization

Public downloads should be signed with a Developer ID Application certificate
and notarized by Apple. Confirm the certificate is installed:

```bash
security find-identity -v -p codesigning
```

Store notarization credentials once using an app-specific password from your
Apple ID account:

```bash
xcrun notarytool store-credentials "voicetype-notary" \
    --apple-id "you@example.com" \
    --team-id "RDYDWP5W98" \
    --password "app-specific-password"
```

Copy `.env.example` to `.env.local` and keep the local file private:

```bash
cp .env.example .env.local
```

`Scripts/release.sh` loads `.env.local` automatically. Without those variables,
ordinary local app builds keep using ad-hoc signing, while `release.sh` refuses
to produce public release artifacts.

## One-time setup: the Sparkle signing key

Sparkle verifies every update with an EdDSA signature. Generate the key pair once:

```bash
swift build   # resolves Sparkle so its tools exist under .build/artifacts
.build/artifacts/sparkle/Sparkle/bin/generate_keys
```

This stores the **private key in your login Keychain** and prints the **public
key**, which is already pinned in `Resources/Info.plist` as `SUPublicEDKey`. If
you regenerate the key, update that value.

For CI, export the private key and add it as the repo secret
**`SPARKLE_PRIVATE_KEY`**:

```bash
.build/artifacts/sparkle/Sparkle/bin/generate_keys -x sparkle_private_key.txt
# paste the file's contents into GitHub → Settings → Secrets → SPARKLE_PRIVATE_KEY
rm sparkle_private_key.txt   # never commit this
```

> The private key is the trust root for updates. Keep it out of the repo. The
> public key in `Info.plist` is safe to publish.

## Prepare the release commit

1. Choose the next `major.minor.patch` version. VoiceType intentionally uses the
   same three-integer value for `CFBundleShortVersionString`,
   `CFBundleVersion`, and the Git tag.

2. Update both version values in `Resources/Info.plist`, then commit the bump:

   ```bash
   /usr/libexec/PlistBuddy \
       -c "Set :CFBundleShortVersionString 2.5.0" \
       -c "Set :CFBundleVersion 2.5.0" \
       Resources/Info.plist
   git add Resources/Info.plist
   git commit -m "chore(release): bump version to 2.5.0"
   ```

3. Merge that commit to `main`. Confirm CI is green, then update the local
   release checkout:

   ```bash
   git switch main
   git pull --ff-only
   git status --short
   ```

   The status output must be empty. `release.sh` also verifies that local `main`
   exactly matches `origin/main` and that the release tag does not already exist.

## Build signed artifacts

Build the release locally:

```bash
Scripts/release.sh 2.5.0
```

This stamps the bundle version, builds the DMG, signs and notarizes the app,
zips and signs the Sparkle update, and writes `appcast.xml` (enclosure URL →
the `v2.5.0` release assets).

Public releases fail closed if Developer ID signing or notarization is not
configured. For a packaging rehearsal on a feature branch only:

```bash
ALLOW_UNNOTARIZED_RELEASE=1 ALLOW_NON_MAIN_RELEASE=1 \
    Scripts/release.sh 2.5.0
```

Those rehearsal artifacts are ad-hoc signed. Never publish or share them.

## Release smoke test

Before publishing, test the signed release candidate on a representative
Apple-silicon Mac. Avoid resetting macOS permissions on your daily-use install;
use a separate test account or machine when you need a true first-run test.

- Install from the generated DMG and confirm Gatekeeper opens it without a
  warning.
- Complete first-run Microphone, Speech Recognition, and Accessibility setup.
- Dictate into at least one native app and one browser; verify hold/tap behavior,
  insertion, clipboard restoration, and Escape cancellation.
- Switch languages and run a short non-English dictation.
- Download, test, select, and remove at least one optional model.
- Transcribe an audio file, then verify copy, history, individual deletion, and
  **Delete all**.
- Turn history off and confirm a new dictation is not retained.
- Check launch-at-login behavior and run **Check for Updates…**.
- Launch once with the network unavailable; installed engines must continue to
  work locally.

## Publish and verify

1. Publish the GitHub Release with all three artifacts:

    ```bash
    gh release create v2.5.0 --target main \
        --title "VoiceType 2.5.0" --notes "What changed…" \
        VoiceType.dmg VoiceType.zip appcast.xml
    ```

    Local is the canonical path: only the maintainer's machine has the Apple
    Developer ID + notary credentials, so the DMG it produces is signed and
    notarized (a plain double-click works).

    `.github/workflows/release.yml` is a manual package check, not a publishing
    fallback. It retains explicitly labeled, unnotarized artifacts for three
    days and cannot create or overwrite a GitHub Release. It needs the
    `SPARKLE_PRIVATE_KEY` repository secret.

2. Verify the public release itself:

    ```bash
    gh release view v2.5.0
    curl -fL -o /tmp/VoiceType.dmg \
        https://github.com/michael-L-i/VoiceType/releases/download/v2.5.0/VoiceType.dmg
    hdiutil verify /tmp/VoiceType.dmg
    ```

    Confirm the release page contains `VoiceType.dmg`, `VoiceType.zip`, and
    `appcast.xml`, and that an existing install sees the update.

That's it. Because the app's `SUFeedURL` points at
`releases/latest/download/appcast.xml`, every existing install will discover the
new version on its next check (or via **Check for Updates…** in the menu) and
offer to install it.

## Notes

- **Bump and commit the version every release.** Sparkle compares
  `CFBundleVersion`; an equal or lower number won't be offered. `release.sh`
  verifies the committed version and stamps the same value into the bundle.
- **The first auto-update-capable build is 0.1.1.** Earlier builds (0.1.0) have no
  updater and must be replaced manually.
- Keep `.env.local` populated for public releases so both the human download and
  Sparkle payload are built from the notarized app.
