#!/usr/bin/env bash
# Mount and verify the exact app contained in the public DMG.
set -euo pipefail

DMG="${1:?usage: Scripts/verify-dmg.sh <VoiceType.dmg>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOUNT_POINT=""

cleanup() {
    if [[ -n "$MOUNT_POINT" ]]; then
        hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

[[ -f "$DMG" ]] || { echo "✗ DMG does not exist: $DMG" >&2; exit 1; }

ATTACH_OUTPUT="$(hdiutil attach -readonly -nobrowse "$DMG")"
MOUNT_POINT="$(printf '%s\n' "$ATTACH_OUTPUT" | tail -1 | awk -F '\t' '{print $NF}')"
[[ -d "$MOUNT_POINT" ]] || { echo "✗ Could not determine mounted DMG path" >&2; exit 1; }

APP="$MOUNT_POINT/VoiceType.app"
[[ -d "$APP" ]] || { echo "✗ DMG does not contain VoiceType.app" >&2; exit 1; }

"$ROOT/Scripts/verify-app.sh" "$APP"
echo "✓ Verified DMG $DMG"
