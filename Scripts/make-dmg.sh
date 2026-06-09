#!/usr/bin/env bash
# Package VoiceType.app into a drag-to-Applications DMG for GitHub Releases.
#
# Builds the app via Scripts/build-app.sh, stages it next to an "Applications"
# symlink, and produces a compressed VoiceType.dmg using only built-in tools
# (hdiutil, ln) — no create-dmg, no AppleScript, no logged-in Finder required,
# so it works deterministically in CI.
#
# Usage: Scripts/make-dmg.sh   (always builds the release configuration)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/VoiceType.app"
DMG="$ROOT/VoiceType.dmg"
VOLNAME="VoiceType"

echo "▸ Building VoiceType.app (release)…"
"$ROOT/Scripts/build-app.sh" release

if [[ ! -d "$APP" ]]; then
    echo "✗ Expected $APP but it was not produced." >&2
    exit 1
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

echo "▸ Verifying DMG…"
hdiutil verify "$DMG"

SIZE="$(du -h "$DMG" | cut -f1 | tr -d '[:space:]')"
echo "✓ Built $DMG ($SIZE)"
