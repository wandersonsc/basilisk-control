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
./scripts/build-app.sh
app_path="$PWD/dist/Basilisk Control.app"
printf 'You can move this app to Applications.\n'
open -R "$app_path"
open "$app_path"
