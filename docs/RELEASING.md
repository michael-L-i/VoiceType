# Releasing VoiceType

VoiceType ships two things per release:

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
the scripts keep using ad-hoc signing for local builds.

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

## Cut a release

1. Pick the next version and build the signed artifacts locally:

   ```bash
   Scripts/release.sh 0.1.2
   ```

   This stamps the bundle version, builds the DMG, signs/notarizes when the
   Developer ID environment variables are set, zips + signs the app, and writes
   `appcast.xml` (enclosure URL → the `v0.1.2` release assets).

2. Publish the GitHub Release with all three artifacts:

   ```bash
   gh release create v0.1.2 --target main \
       --title "VoiceType 0.1.2" --notes "What changed…" \
       VoiceType.dmg VoiceType.zip appcast.xml
   ```

   Local is the canonical path: only the maintainer's machine has the Apple
   Developer ID + notary credentials, so the DMG it produces is signed and
   notarized (a plain double-click works). `.github/workflows/release.yml` exists
   as a **manual** fallback (Actions → Release → Run workflow) for a machine-less
   release — but a GitHub runner can't notarize, so its DMG is ad-hoc only. Don't
   run it to re-publish a tag you already released locally; it would overwrite the
   notarized DMG. It also needs the `SPARKLE_PRIVATE_KEY` repo secret.

That's it. Because the app's `SUFeedURL` points at
`releases/latest/download/appcast.xml`, every existing install will discover the
new version on its next check (or via **Check for Updates…** in the menu) and
offer to install it.

## Notes

- **Bump the version every release.** Sparkle compares `CFBundleVersion`; an equal
  or lower number won't be offered. `release.sh` handles the stamping.
- **The first auto-update-capable build is 0.1.1.** Earlier builds (0.1.0) have no
  updater and must be replaced manually.
- Keep `.env.local` populated for public releases so both the human download and
  Sparkle payload are built from the notarized app.
