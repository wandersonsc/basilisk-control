#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(uname -s)" != Darwin ]; then
    printf 'Build this native app on a Mac.\n' >&2
    exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
    printf 'Install Apple command line tools with: xcode-select --install\n' >&2
    exit 1
fi
if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != --universal ]; }; then
    printf 'Usage: %s [--universal]\n' "$0" >&2
    exit 1
fi

./test-protocol.sh
app_path="$PWD/dist/Basilisk Control.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

if [ "${1:-}" = --universal ]; then
    for architecture in arm64 x86_64; do
        swift build -c release --arch "$architecture" --product BasiliskControl
    done
    arm_bin_dir=$(swift build -c release --arch arm64 --show-bin-path)
    intel_bin_dir=$(swift build -c release --arch x86_64 --show-bin-path)
    lipo -create "$arm_bin_dir/BasiliskControl" "$intel_bin_dir/BasiliskControl" \
        -output "$app_path/Contents/MacOS/BasiliskControl"
    lipo "$app_path/Contents/MacOS/BasiliskControl" -verify_arch arm64 x86_64
else
    swift build -c release --product BasiliskControl
    bin_dir=$(swift build -c release --show-bin-path)
    cp "$bin_dir/BasiliskControl" "$app_path/Contents/MacOS/BasiliskControl"
fi

cp Resources/Info.plist "$app_path/Contents/Info.plist"
cp Resources/Basilisk.icns "$app_path/Contents/Resources/Basilisk.icns"
plutil -lint "$app_path/Contents/Info.plist"
codesign --force --sign - "$app_path"
codesign --verify --strict "$app_path"
ditto -c -k --sequesterRsrc --keepParent "$app_path" dist/Basilisk-Control-macOS.zip
(
    cd dist
    shasum -a 256 Basilisk-Control-macOS.zip > Basilisk-Control-macOS.zip.sha256
)
printf '\nBuilt: %s\nArchive: %s/dist/Basilisk-Control-macOS.zip\n' "$app_path" "$PWD"
