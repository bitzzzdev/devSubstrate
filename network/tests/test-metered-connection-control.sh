#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/network/scripts/metered-connection-control.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"
printf '%s\n' unknown > "$TMP/state"

cat > "$TMP/bin/nmcli" <<'NMCLI'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == "-t" && "$2" == "-f" && "$3" == "UUID,TYPE" ]]; then
    if [[ "${NMCLI_NO_WIFI:-0}" == "1" ]]; then
        exit 0
    fi
    printf '%s\n' 'test-uuid:802-11-wireless'
elif [[ "$1" == "-g" && "$2" == "connection.id" ]]; then
    printf '%s\n' 'Test Wi-Fi'
elif [[ "$1" == "-g" && "$2" == "connection.metered" ]]; then
    cat "$NMCLI_STATE_FILE"
elif [[ "$1" == "connection" && "$2" == "modify" ]]; then
    printf '%s\n' "$5" > "$NMCLI_STATE_FILE"
else
    echo "Unexpected nmcli invocation: $*" >&2
    exit 2
fi
NMCLI
chmod +x "$TMP/bin/nmcli"

export PATH="$TMP/bin:$PATH"
export NMCLI_STATE_FILE="$TMP/state"

output="$(bash "$SCRIPT" apply)"
grep -q 'Marked Wi-Fi profile as metered: Test Wi-Fi' <<< "$output"
[[ "$(cat "$TMP/state")" == "yes" ]]

output="$(bash "$SCRIPT" status)"
grep -q 'Metered setting: yes' <<< "$output"

output="$(bash "$SCRIPT" revert)"
grep -q 'Restored automatic metered detection for: Test Wi-Fi' <<< "$output"
[[ "$(cat "$TMP/state")" == "unknown" ]]

if NMCLI_NO_WIFI=1 bash "$SCRIPT" status >"$TMP/no-wifi.out" 2>&1; then
    echo "Expected status to fail when no active Wi-Fi profile exists." >&2
    exit 1
fi
grep -q 'no active NetworkManager Wi-Fi connection' "$TMP/no-wifi.out"

echo "PASS: metered apply, status, revert, and no-active-Wi-Fi handling."
if command -v fish >/dev/null 2>&1; then
    fish -n "$ROOT/network/scripts/metered-connection-control.fish"
    echo "PASS: Fish syntax."
else
    echo "SKIP: fish is not installed; Fish syntax was not checked."
fi
