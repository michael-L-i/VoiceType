#!/usr/bin/env bash
# Build VoiceType.app — a self-contained menu-bar bundle from the SwiftPM
# executable. Ad-hoc codesigned so TCC (mic / speech / accessibility) prompts
# behave. Re-run after code changes.
#
# Usage: Scripts/build-app.sh [debug|release]   (default: release)
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/VoiceType.app"
CONTENTS="$APP/Contents"

echo "▸ Building VoiceType ($CONFIG)…"
swift build -c "$CONFIG" --package-path "$ROOT"
BIN="$(swift build -c "$CONFIG" --package-path "$ROOT" --show-bin-path)/VoiceType"

echo "▸ Assembling bundle…"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN" "$CONTENTS/MacOS/VoiceType"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

echo "▸ Codesigning (ad-hoc)…"
codesign --force --sign - \
    --entitlements "$ROOT/Resources/VoiceType.entitlements" \
    --options runtime \
    "$APP" 2>/dev/null || \
codesign --force --sign - \
    --entitlements "$ROOT/Resources/VoiceType.entitlements" \
    "$APP"

echo "✓ Built $APP"
echo "  Launch:  open \"$APP\"   (or: \"$CONTENTS/MacOS/VoiceType\" for logs)"
