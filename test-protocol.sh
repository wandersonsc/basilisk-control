#!/bin/sh
set -eu
cd "$(dirname "$0")"
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/basilisk-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
cc -std=c11 -Wall -Wextra -Werror -pedantic \
  -I Sources/BasiliskHID/include Sources/BasiliskHID/Protocol.c \
  Tests/ProtocolTests.c -o "$test_dir/protocol-tests"
"$test_dir/protocol-tests"
