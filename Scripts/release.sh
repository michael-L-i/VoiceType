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
#
# Public releases fail closed: the source version must already be committed on
# main, and Developer ID signing + notarization must be configured. For a local
# packaging rehearsal only, set ALLOW_UNNOTARIZED_RELEASE=1 and
# ALLOW_NON_MAIN_RELEASE=1; never publish those artifacts.
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
INFO_PLIST="$ROOT/Resources/Info.plist"

export VERSION

if [[ ! "$VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    echo "✗ Version must be three dot-separated integers, for example 2.5.0." >&2
    exit 1
fi

SOURCE_SHORT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
SOURCE_BUILD_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"
if [[ "$SOURCE_SHORT_VERSION" != "$VERSION" || "$SOURCE_BUILD_VERSION" != "$VERSION" ]]; then
    echo "✗ Resources/Info.plist must declare $VERSION before release." >&2
    echo "  Update both bundle versions, commit the change, and release from main." >&2
    exit 1
fi

CURRENT_BRANCH="$(git -C "$ROOT" branch --show-current)"
if [[ "$CURRENT_BRANCH" != "main" && "${ALLOW_NON_MAIN_RELEASE:-0}" != "1" ]]; then
    echo "✗ Public releases must be built from main (current: ${CURRENT_BRANCH:-detached HEAD})." >&2
    exit 1
fi

if ! git -C "$ROOT" diff --quiet || ! git -C "$ROOT" diff --cached --quiet; then
    echo "✗ Tracked files are modified. Commit or restore them before releasing." >&2
    exit 1
fi

if [[ "${ALLOW_NON_MAIN_RELEASE:-0}" != "1" ]]; then
    git -C "$ROOT" fetch --quiet origin main --tags
    if [[ "$(git -C "$ROOT" rev-parse HEAD)" != "$(git -C "$ROOT" rev-parse origin/main)" ]]; then
        echo "✗ Local main must exactly match origin/main before release." >&2
        exit 1
    fi
fi

if git -C "$ROOT" rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    echo "✗ Tag $TAG already exists; never overwrite published release artifacts." >&2
    exit 1
fi

if [[ "${ALLOW_UNNOTARIZED_RELEASE:-0}" != "1" ]]; then
    if [[ -z "${DEVELOPER_ID_APPLICATION:-}" || -z "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
        echo "✗ Public releases require DEVELOPER_ID_APPLICATION and NOTARY_KEYCHAIN_PROFILE." >&2
        echo "  Configure .env.local as documented in docs/RELEASING.md." >&2
        exit 1
    fi
else
    echo "⚠ Building an unnotarized release rehearsal. Do not publish these artifacts." >&2
fi

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
KEYFILE=""
cleanup() {
    if [[ -n "$KEYFILE" ]]; then
        rm -f -- "$KEYFILE"
    fi
    rm -rf -- "$ARCH_DIR"
}
trap cleanup EXIT
cp "$ZIP" "$ARCH_DIR/"

KEYARGS=()
if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
    KEYFILE="$(mktemp)"
    chmod 600 "$KEYFILE"
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
