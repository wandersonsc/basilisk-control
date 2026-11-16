#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
on_exit() {
    local result=$?
    if [ "$result" -ne 0 ]; then
        printf '\nBuild failed. See the error above. You need macOS 13+ and Xcode 15+ command line tools (Swift 5.9+).\n'
        read -r -p 'Press Return to close… ' || true
    fi
}
trap on_exit EXIT
if [ "$(uname -s)" != "Darwin" ]; then
    printf 'Build this native app on a Mac.\n'
    exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
    printf 'Install Apple command line tools with: xcode-select --install\nThen run this script again after installation completes.\n'
    exit 1
fi
./test-protocol.sh
swift build -c release --product BasiliskControl
bin_dir=$(swift build -c release --show-bin-path)
app_path="$PWD/dist/Basilisk Control.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$bin_dir/BasiliskControl" "$app_path/Contents/MacOS/BasiliskControl"
cp Resources/Info.plist "$app_path/Contents/Info.plist"
cp Resources/Basilisk.icns "$app_path/Contents/Resources/Basilisk.icns"
codesign --force --sign - "$app_path"
codesign --verify --strict "$app_path"
printf '\nBuilt: %s\nYou can move this app to Applications.\n' "$app_path"
open -R "$app_path"
open "$app_path"
