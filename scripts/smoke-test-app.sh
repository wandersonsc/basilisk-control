#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

app_binary="$PWD/dist/Basilisk Control.app/Contents/MacOS/BasiliskControl"
log_file="$PWD/dist/launch-smoke-test.log"
"$app_binary" >"$log_file" 2>&1 &
app_pid=$!
cleanup() {
    kill "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null || true
}
trap cleanup EXIT
sleep 5
if ! kill -0 "$app_pid" 2>/dev/null; then
    cat "$log_file"
    printf 'The app exited during its launch smoke test.\n' >&2
    exit 1
fi
printf 'PASS: the native app remained running after launch. No physical mouse controls were tested.\n'
