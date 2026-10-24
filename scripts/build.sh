#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

case "${1:-}" in
    "") ARCHITECTURES=("$(uname -m)") ;;
    --universal) ARCHITECTURES=(arm64 x86_64) ;;
    *) echo "Usage: $0 [--universal]" >&2; exit 1 ;;
esac

BINARIES=()
for arch in "${ARCHITECTURES[@]}"; do
    swift build --configuration release --arch "$arch" --scratch-path ".build/$arch"
    BIN_DIR="$(swift build --configuration release --arch "$arch" --scratch-path ".build/$arch" --show-bin-path)"
    BINARIES+=("$BIN_DIR/Caffeinate")
done

APP="$ROOT/dist/Caffeinate.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [[ ${#BINARIES[@]} -eq 1 ]]; then
    cp "${BINARIES[0]}" "$APP/Contents/MacOS/Caffeinate"
else
    lipo -create "${BINARIES[@]}" -output "$APP/Contents/MacOS/Caffeinate"
fi
cp Resources/Info.plist "$APP/Contents/Info.plist"
swift scripts/generate-icon.swift .build/AppIcon.iconset
iconutil --convert icns .build/AppIcon.iconset --output "$APP/Contents/Resources/AppIcon.icns"
plutil -lint "$APP/Contents/Info.plist"
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --strict "$APP"
echo "Built: $APP"
