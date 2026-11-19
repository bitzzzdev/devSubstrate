#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/adb" <<'ADB'
#!/bin/sh
exit 0
ADB

cat > "$TMP/curl" <<'CURL'
#!/bin/sh
case "$*" in
    *manage-shopping-traffic.sh*)
        printf '%s\n' 'echo SHOPPING_STAGE; exit 1'
        ;;
    *hotspot-background-traffic-control.sh*)
        printf '%s\n' 'echo HOTSPOT_STAGE'
        ;;
    *)
        printf '%s\n' 'echo UNEXPECTED_STAGE; exit 2'
        ;;
esac
CURL

chmod +x "$TMP/adb" "$TMP/curl"
set +e
PATH="$TMP:$PATH" bash "$ROOT/androidCurlScripts.sh" 2 >"$TMP/output" 2>&1
status=$?
set -e

grep -q '^SHOPPING_STAGE$' "$TMP/output"
grep -q '^HOTSPOT_STAGE$' "$TMP/output"
if [[ "$status" -eq 0 ]]; then
    echo "Expected aggregate failure after the partial shopping stage." >&2
    exit 1
fi

echo "PASS: option 2 defaults to all, executes hotspot after a partial shopping failure, and returns a non-zero aggregate status."
