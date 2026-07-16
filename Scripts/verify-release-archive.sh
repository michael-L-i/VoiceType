#!/usr/bin/env bash
# Extract and verify the exact Sparkle ZIP that will be published. This prevents
# release packaging from dropping resources after the assembled app was checked.
set -euo pipefail

ARCHIVE="${1:?usage: Scripts/verify-release-archive.sh <VoiceType.zip>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$ARCHIVE" ]] || { echo "✗ Archive does not exist: $ARCHIVE" >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
ditto -x -k "$ARCHIVE" "$STAGE"

APP="$STAGE/VoiceType.app"
[[ -d "$APP" ]] || { echo "✗ Archive does not contain VoiceType.app" >&2; exit 1; }

"$ROOT/Scripts/verify-app.sh" "$APP"
echo "✓ Verified release archive $ARCHIVE"
