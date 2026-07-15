#!/usr/bin/env bash
# Cut a release. Produces three artifacts:
#   • VoiceType.dmg   — the human download (drag-to-Applications)
#   • VoiceType.zip   — the Sparkle auto-update payload
#   • appcast.xml     — the signed Sparkle feed pointing at the .zip
#
# The app is stamped with <version> so Sparkle can tell builds apart. The .zip is
# signed with the EdDSA private key — read from the Keychain by default, or from
# the SPARKLE_PRIVATE_KEY env var (used in CI). The matching public key is pinned
# in Info.plist as SUPublicEDKey; the private key is NEVER committed.
#
# Usage: Scripts/release.sh <version>          e.g. Scripts/release.sh 0.1.1
# Then:  gh release create v<version> --target <branch> \
#            --title "VoiceType <version>" --notes "…" \
#            VoiceType.dmg VoiceType.zip appcast.xml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -f "$ROOT/.env.local" ]]; then
    echo "▸ Loading local release config from .env.local…"
    set -a
    # shellcheck disable=SC1091
    source "$ROOT/.env.local"
    set +a
fi

RAW="${1:?usage: Scripts/release.sh <version>   (e.g. 0.1.1)}"
VERSION="${RAW#v}"
TAG="v$VERSION"
REPO="michael-L-i/VoiceType"
APP="$ROOT/VoiceType.app"
ZIP="$ROOT/VoiceType.zip"
APPCAST="$ROOT/appcast.xml"

export VERSION

echo "▸ Building + packaging DMG (version $VERSION)…"
"$ROOT/Scripts/make-dmg.sh"          # builds the stamped VoiceType.app + VoiceType.dmg

echo "▸ Zipping app for Sparkle…"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
"$ROOT/Scripts/verify-release-archive.sh" "$ZIP"

GEN_APPCAST="$(find "$ROOT/.build/artifacts" -path "*sparkle*/bin/generate_appcast" | head -1)"
if [[ -z "$GEN_APPCAST" ]]; then
    echo "✗ generate_appcast not found (did the Sparkle package resolve?)" >&2
    exit 1
fi

echo "▸ Generating signed appcast…"
ARCH_DIR="$(mktemp -d)"
trap 'rm -rf "$ARCH_DIR"' EXIT
cp "$ZIP" "$ARCH_DIR/"

KEYARGS=()
if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
    KEYFILE="$(mktemp)"
    printf '%s' "$SPARKLE_PRIVATE_KEY" > "$KEYFILE"
    KEYARGS=(--ed-key-file "$KEYFILE")
fi

# Guard the array expansion for macOS's bash 3.2 under `set -u`.
"$GEN_APPCAST" ${KEYARGS[@]+"${KEYARGS[@]}"} \
    --download-url-prefix "https://github.com/$REPO/releases/download/$TAG/" \
    "$ARCH_DIR"
cp "$ARCH_DIR/appcast.xml" "$APPCAST"

echo
echo "✓ Release artifacts for $TAG:"
echo "    VoiceType.dmg   — human download"
echo "    VoiceType.zip   — Sparkle update payload"
echo "    appcast.xml     — Sparkle feed"
echo
echo "Publish:"
echo "    gh release create $TAG --target \"\$(git branch --show-current)\" \\"
echo "        --title \"VoiceType $VERSION\" --notes \"…\" \\"
echo "        VoiceType.dmg VoiceType.zip appcast.xml"
