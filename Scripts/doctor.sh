#!/usr/bin/env bash
# Clean up VoiceType's bundle-id hygiene. Every build (repo dev build, DMG,
# temp test copies from make-dmg.sh/release.sh) shares one bundle id,
# com.voicetype.app. Stray LaunchServices registrations and mounted DMG
# volumes left over from packaging/testing can make LaunchServices and the
# window server confuse processes that claim the same id — e.g. a stale
# process's floating recording HUD getting stuck on whatever Space it was
# last drawn on, or Accessibility grants not "sticking."
#
# Run this before relaunching the local dev build if something looks off.
#
# Usage: Scripts/doctor.sh
set -euo pipefail

BUNDLE_ID="com.voicetype.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

echo "▸ Quitting any running VoiceType…"
osascript -e 'quit app "VoiceType"' >/dev/null 2>&1 || true
pkill -x VoiceType 2>/dev/null || true

echo "▸ Ejecting stray VoiceType DMG volumes…"
for VOL in /Volumes/VoiceType*; do
    [[ -d "$VOL" ]] || continue
    echo "  - ejecting $VOL"
    diskutil eject "$VOL" >/dev/null 2>&1 || echo "    ⚠ could not eject $VOL (in use?)"
done

echo "▸ Auditing LaunchServices registrations for ${BUNDLE_ID}…"
PATHS=()
while IFS= read -r P; do
    PATHS+=("$P")
done < <("$LSREGISTER" -dump 2>/dev/null \
    | grep -oE 'path:.*VoiceType\.app' \
    | sed 's/^path:[[:space:]]*//' \
    | sort -u)

if [[ "${#PATHS[@]}" -eq 0 ]]; then
    echo "  (no registrations found)"
else
    STALE=()
    LIVE=()
    for P in "${PATHS[@]}"; do
        if [[ -d "$P" ]]; then
            LIVE+=("$P")
        else
            STALE+=("$P")
        fi
    done

    if [[ "${#STALE[@]}" -gt 0 ]]; then
        echo "  Unregistering ${#STALE[@]} stale path(s) (no longer on disk):"
        for P in "${STALE[@]}"; do
            echo "    - $P"
            "$LSREGISTER" -u "$P" 2>/dev/null || true
        done
    fi

    if [[ "${#LIVE[@]}" -gt 0 ]]; then
        echo "  ${#LIVE[@]} live path(s) still claim $BUNDLE_ID:"
        for P in "${LIVE[@]}"; do
            echo "    - $P"
        done
        if [[ "${#LIVE[@]}" -gt 1 ]]; then
            echo "  ⚠ More than one copy exists on disk — run ONE at a time." \
                 "Quit/trash the others (or an installed /Applications copy)" \
                 "before launching the repo dev build."
        fi
    fi
fi

echo "✓ Doctor pass complete."
echo "  If the local build's hotkey/Accessibility grant looks stale afterwards:"
echo "    tccutil reset Accessibility $BUNDLE_ID"
