#!/usr/bin/env bash
# Verify every UI localization ships the same key set. English is the
# reference; any .lproj that adds or drops a key fails the check, so a merged
# PR can't silently leave a language half-translated.
#
# Usage: Scripts/check-l10n.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RES="$ROOT/Sources/VoiceType/Resources"
REFERENCE="$RES/en.lproj/Localizable.strings"

keys() {
    plutil -convert json -o - "$1" | python3 -c '
import json, sys
print("\n".join(sorted(json.load(sys.stdin).keys())))'
}

# Syntax-check every file first so a stray quote fails with a clear message.
for f in "$RES"/*.lproj/Localizable.strings; do
    plutil -lint "$f" > /dev/null
done

status=0
ref_keys="$(keys "$REFERENCE")"
for f in "$RES"/*.lproj/Localizable.strings; do
    [[ "$f" == "$REFERENCE" ]] && continue
    if ! diff <(echo "$ref_keys") <(keys "$f") > /dev/null; then
        echo "✗ Key set of $f differs from en.lproj:"
        diff <(echo "$ref_keys") <(keys "$f") | sed 's/^</  only in en:/; s/^>/  only here:/' | grep -v '^---' || true
        status=1
    fi
done

if [[ $status -eq 0 ]]; then
    echo "✓ All localizations carry the same $(echo "$ref_keys" | wc -l | tr -d ' ') keys."
fi
exit $status
