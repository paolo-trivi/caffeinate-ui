#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/build.sh" --universal

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/caffeinate-package.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$ROOT/dist/Caffeinate.app" "$STAGING/Caffeinate.app"
ln -s /Applications "$STAGING/Applications"
ditto -c -k --sequesterRsrc --keepParent "$ROOT/dist/Caffeinate.app" "$ROOT/dist/Caffeinate-macOS-universal.zip"
hdiutil create -volname Caffeinate -srcfolder "$STAGING" -format UDZO -ov "$ROOT/dist/Caffeinate-macOS-universal.dmg"
(
    cd "$ROOT/dist"
    shasum -a 256 Caffeinate-macOS-universal.zip Caffeinate-macOS-universal.dmg > SHA256SUMS
)
echo "Packages: $ROOT/dist/"
