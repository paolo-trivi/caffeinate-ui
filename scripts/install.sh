#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/build.sh"

DESTINATION="$HOME/Applications/Caffeinate.app"
if pgrep -x Caffeinate >/dev/null; then
    echo "Quit Caffeinate before installing an update." >&2
    exit 1
fi
if [[ -e "$DESTINATION" ]]; then
    IDENTIFIER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DESTINATION/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$IDENTIFIER" != "dev.caffeinate.widget" ]]; then
        echo "Refusing to replace a different app at $DESTINATION" >&2
        exit 1
    fi
fi
mkdir -p "$HOME/Applications"
ditto "$ROOT/dist/Caffeinate.app" "$DESTINATION"
open "$DESTINATION"
echo "Installed: $DESTINATION"
