#!/usr/bin/env bash
# Build VoiceType.app — a self-contained Dock-app bundle from the SwiftPM
# executable. Ad-hoc codesigned by default so TCC (mic / speech /
# accessibility) prompts behave. Set DEVELOPER_ID_APPLICATION for public
# Developer ID releases.
#
# Usage: Scripts/build-app.sh [debug|release]   (default: release)
#   VERSION=0.1.2 Scripts/build-app.sh   → stamp the bundle version (for Sparkle)
#   DEVELOPER_ID_APPLICATION="Developer ID Application: Name (TEAMID)" Scripts/build-app.sh
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/VoiceType.app"
CONTENTS="$APP/Contents"
# Marketing/build version. A release sets VERSION (e.g. from the git tag); local
# dev builds fall back to whatever the template Info.plist already declares.
VERSION="${VERSION:-}"
SIGN_IDENTITY="${DEVELOPER_ID_APPLICATION:--}"

echo "▸ Building VoiceType ($CONFIG)…"
swift build -c "$CONFIG" --package-path "$ROOT"
BIN="$(swift build -c "$CONFIG" --package-path "$ROOT" --show-bin-path)/VoiceType"

echo "▸ Assembling bundle…"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN" "$CONTENTS/MacOS/VoiceType"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
# Vendor logos (e.g. the NVIDIA mark shown on the Models page).
cp "$ROOT"/Resources/*.svg "$CONTENTS/Resources/" 2>/dev/null || true
# Third-party license notices, bundled so they ship with the distributed app.
cp "$ROOT/THIRD_PARTY_LICENSES.md" "$CONTENTS/Resources/" 2>/dev/null || true

# Embed dynamic frameworks (Sparkle ships as a framework with nested helpers)
# next to the binary's runtime search path. SwiftPM builds the framework beside
# the executable but doesn't bundle it, so we copy it and add the standard app
# rpath so dyld finds it at @executable_path/../Frameworks.
BINDIR="$(dirname "$BIN")"
if [[ -d "$BINDIR/Sparkle.framework" ]]; then
    echo "▸ Embedding Sparkle.framework…"
    mkdir -p "$CONTENTS/Frameworks"
    cp -RP "$BINDIR/Sparkle.framework" "$CONTENTS/Frameworks/"
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$CONTENTS/MacOS/VoiceType" 2>/dev/null || true
fi

if [[ -n "$VERSION" ]]; then
    echo "▸ Stamping version ${VERSION}…"
    PB=/usr/libexec/PlistBuddy
    "$PB" -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"
    "$PB" -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"
fi

# Nested Sparkle helpers/XPC must be signed too. Sign the framework first
# (inside-out), then the whole app. Public builds need Developer ID signing with
# the hardened runtime so Apple will notarize the app.
SIGN_ARGS=(--force --deep --sign "$SIGN_IDENTITY")
if [[ "$SIGN_IDENTITY" != "-" ]]; then
    SIGN_ARGS+=(--options runtime --timestamp)
fi

if [[ "$SIGN_IDENTITY" == "-" ]]; then
    echo "▸ Codesigning (ad-hoc, deep)…"
else
    echo "▸ Codesigning with Developer ID: ${SIGN_IDENTITY}…"
fi
if [[ -d "$CONTENTS/Frameworks/Sparkle.framework" ]]; then
    codesign "${SIGN_ARGS[@]}" "$CONTENTS/Frameworks/Sparkle.framework"
fi
codesign "${SIGN_ARGS[@]}" \
    --entitlements "$ROOT/Resources/VoiceType.entitlements" \
    "$APP"

echo "✓ Built $APP"
echo "  Launch:  open \"$APP\"   (or: \"$CONTENTS/MacOS/VoiceType\" for logs)"
