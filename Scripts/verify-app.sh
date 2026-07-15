#!/usr/bin/env bash
# Verify a fully assembled VoiceType.app, including its runtime resource closure.
# The optional second argument is SwiftPM's build-products directory; when
# supplied, every generated resource bundle must be present in the app.
set -euo pipefail

APP="${1:?usage: Scripts/verify-app.sh <VoiceType.app> [swiftpm-bin-dir]}"
BINDIR="${2:-}"
CONTENTS="$APP/Contents"
RESOURCES="$CONTENTS/Resources"
EXECUTABLE="$CONTENTS/MacOS/VoiceType"

fail() {
    echo "✗ $*" >&2
    exit 1
}

[[ -d "$APP" ]] || fail "App bundle does not exist: $APP"
[[ -f "$CONTENTS/Info.plist" ]] || fail "App bundle has no Info.plist"
[[ -x "$EXECUTABLE" ]] || fail "App bundle has no executable VoiceType binary"

for REQUIRED_BUNDLE in VoiceType_VoiceType.bundle swift-transformers_Hub.bundle; do
    [[ -d "$RESOURCES/$REQUIRED_BUNDLE" ]] \
        || fail "Missing runtime resource bundle: $REQUIRED_BUNDLE"
done

if find "$APP" -maxdepth 1 -type d -name '*.bundle' -print -quit | grep -q .; then
    fail "Resource bundles must be under Contents/Resources, not the app root"
fi

if [[ -n "$BINDIR" ]]; then
    FOUND_BUILD_BUNDLE=0
    for SOURCE_BUNDLE in "$BINDIR"/*.bundle; do
        [[ -d "$SOURCE_BUNDLE" ]] || continue
        FOUND_BUILD_BUNDLE=1
        NAME="$(basename "$SOURCE_BUNDLE")"
        [[ -d "$RESOURCES/$NAME" ]] || fail "Build resource bundle was not packaged: $NAME"
        diff -qr "$SOURCE_BUNDLE" "$RESOURCES/$NAME" >/dev/null \
            || fail "Packaged resource bundle differs from build output: $NAME"
    done
    [[ "$FOUND_BUILD_BUNDLE" -eq 1 ]] || fail "Build directory contains no resource bundles"
fi

codesign --verify --deep --strict --verbose=2 "$APP"
"$EXECUTABLE" --verify-package

echo "✓ Verified $APP"
