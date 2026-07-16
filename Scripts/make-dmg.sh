#!/usr/bin/env bash
# Package VoiceType.app into a drag-to-Applications DMG for GitHub Releases.
#
# Builds the app via Scripts/build-app.sh, optionally notarizes/staples the app,
# stages it next to an "Applications" symlink, and produces a compressed
# VoiceType.dmg using only built-in tools (hdiutil, ln) — no create-dmg, no
# AppleScript, no logged-in Finder required, so it works deterministically in CI.
#
# Usage: Scripts/make-dmg.sh   (always builds the release configuration)
#   DEVELOPER_ID_APPLICATION="Developer ID Application: Name (TEAMID)" \
#   NOTARY_KEYCHAIN_PROFILE=voicetype-notary Scripts/make-dmg.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/VoiceType.app"
DMG="$ROOT/VoiceType.dmg"
VOLNAME="VoiceType"
NOTARY_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"

echo "▸ Building VoiceType.app (release)…"
"$ROOT/Scripts/build-app.sh" release

if [[ ! -d "$APP" ]]; then
    echo "✗ Expected $APP but it was not produced." >&2
    exit 1
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
    if [[ "${DEVELOPER_ID_APPLICATION:-}" == "" ]]; then
        echo "✗ NOTARY_KEYCHAIN_PROFILE requires DEVELOPER_ID_APPLICATION." >&2
        exit 1
    fi

    echo "▸ Notarizing app for Sparkle updates…"
    APP_ZIP="$(mktemp -t voicetype-app-notary).zip"
    ditto -c -k --sequesterRsrc --keepParent "$APP" "$APP_ZIP"
    xcrun notarytool submit "$APP_ZIP" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    rm -f "$APP_ZIP"

    echo "▸ Stapling app notarization ticket…"
    xcrun stapler staple "$APP"
fi

echo "▸ Staging DMG contents…"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/VoiceType.app"
ln -s /Applications "$STAGE/Applications"

echo "▸ Creating ${DMG}…"
rm -f "$DMG"
hdiutil create \
    -volname "$VOLNAME" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG"

if [[ "${DEVELOPER_ID_APPLICATION:-}" != "" ]]; then
    echo "▸ Codesigning DMG…"
    codesign --force \
        --sign "$DEVELOPER_ID_APPLICATION" \
        --timestamp \
        "$DMG"
fi

echo "▸ Verifying DMG…"
hdiutil verify "$DMG"
"$ROOT/Scripts/verify-dmg.sh" "$DMG"

if [[ -n "$NOTARY_PROFILE" ]]; then
    echo "▸ Notarizing DMG…"
    xcrun notarytool submit "$DMG" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait

    echo "▸ Stapling DMG notarization ticket…"
    xcrun stapler staple "$DMG"

    echo "▸ Assessing DMG with Gatekeeper…"
    spctl --assess --type open --context context:primary-signature -v "$DMG"
fi

SIZE="$(du -h "$DMG" | cut -f1 | tr -d '[:space:]')"
echo "✓ Built $DMG ($SIZE)"
