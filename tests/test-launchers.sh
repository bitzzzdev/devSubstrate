#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"

cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
output=""
url=""
while (($#)); do
    case "$1" in
        --output)
            output="$2"
            shift 2
            ;;
        --*)
            shift
            ;;
        *)
            url="$1"
            shift
            ;;
    esac
done
printf '%s\n' "$url" >> "$CURL_URL_LOG"
if [[ "${CURL_FAIL:-0}" == "1" ]]; then
    echo "curl: (22) The requested URL returned error: 404" >&2
    exit 22
fi
case "$url" in
    */manage-shopping-traffic.sh)
        cat > "$output" <<'SCRIPT'
echo SHOPPING_STAGE
exit 1
SCRIPT
        ;;
    */hotspot-background-traffic-control.sh)
        cat > "$output" <<'SCRIPT'
echo HOTSPOT_STAGE
SCRIPT
        ;;
    */metered-connection-control.sh)
        cat > "$output" <<'SCRIPT'
echo "METERED_STAGE:$1"
echo "HOME=$HOME"
SCRIPT
        ;;
    */qca9377-powersave-fix.sh)
        cat > "$output" <<'SCRIPT'
echo "QCA9377_STAGE:$1"
SCRIPT
        ;;
    *)
        cat > "$output" <<'SCRIPT'
echo "REMOTE_STAGE:$1"
echo "HOME=$HOME"
SCRIPT
        ;;
esac
CURL
cat > "$TMP/bin/adb" <<'ADB'
#!/usr/bin/env bash
exit 0
ADB
cat > "$TMP/bin/getent" <<'GETENT'
#!/usr/bin/env bash
printf '%s\\n' 'launcher-test:x:1000:1000::/home/launcher-test:/bin/bash'
GETENT
chmod +x "$TMP/bin/curl" "$TMP/bin/adb" "$TMP/bin/getent"

export PATH="$TMP/bin:$PATH"
export CURL_URL_LOG="$TMP/urls.log"

output="$(bash "$ROOT/linuxCurlScripts.sh" 2 wifi)"
grep -q '^METERED_STAGE:apply$' <<< "$output"
grep -q 'gitlab.com/bitzzdev/devSubstrate/-/raw/dev/network/scripts/metered-connection-control.sh
output="$(DEVSUBSTRATE_REMOTE=github bash "$ROOT/linuxCurlScripts.sh" 4 qca9377)"
grep -q '^QCA9377_STAGE:apply$' <<< "$output"
grep -q 'raw.githubusercontent.com/bitzzdev/devSubstrate/dev/network/wifi/scripts/qca9377-powersave-fix.sh$' "$CURL_URL_LOG"

: > "$CURL_URL_LOG"
set +e
output="$(bash "$ROOT/androidCurlScripts.sh" 2 all 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q '^SHOPPING_STAGE$' <<< "$output"
grep -q '^HOTSPOT_STAGE$' <<< "$output"
grep -q 'android/scripts/manage-shopping-traffic.sh$' "$CURL_URL_LOG"
grep -q 'network/scripts/hotspot-background-traffic-control.sh$' "$CURL_URL_LOG"

set +e
output="$(CURL_FAIL=1 bash "$ROOT/linuxCurlScripts.sh" 2 wifi 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q 'failed to fetch implementation script: network/scripts/metered-connection-control.sh' <<< "$output"
grep -q 'https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/network/scripts/metered-connection-control.sh' <<< "$output"

echo "PASS: GitLab default, GitHub override, Wi-Fi metering route, QCA9377 route, Android aggregate execution, and fetch failure reporting."
 "$CURL_URL_LOG"

output="$(SUDO_USER=launcher-test HOME=/root bash "$ROOT/linuxCurlScripts.sh" 2 wifi)"
grep -q '^HOME=/home/launcher-test
output="$(DEVSUBSTRATE_REMOTE=github bash "$ROOT/linuxCurlScripts.sh" 4 qca9377)"
grep -q '^QCA9377_STAGE:apply$' <<< "$output"
grep -q 'raw.githubusercontent.com/bitzzdev/devSubstrate/dev/network/wifi/scripts/qca9377-powersave-fix.sh$' "$CURL_URL_LOG"

: > "$CURL_URL_LOG"
set +e
output="$(bash "$ROOT/androidCurlScripts.sh" 2 all 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q '^SHOPPING_STAGE$' <<< "$output"
grep -q '^HOTSPOT_STAGE$' <<< "$output"
grep -q 'android/scripts/manage-shopping-traffic.sh$' "$CURL_URL_LOG"
grep -q 'network/scripts/hotspot-background-traffic-control.sh$' "$CURL_URL_LOG"

set +e
output="$(CURL_FAIL=1 bash "$ROOT/linuxCurlScripts.sh" 2 wifi 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q 'failed to fetch implementation script: network/scripts/metered-connection-control.sh' <<< "$output"
grep -q 'https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/network/scripts/metered-connection-control.sh' <<< "$output"

echo "PASS: GitLab default, GitHub override, Wi-Fi metering route, QCA9377 route, Android aggregate execution, and fetch failure reporting."
 <<< "$output"

output="$(SUDO_USER=launcher-test HOME=/root bash "$ROOT/androidCurlScripts.sh" 3 gcloud)"
grep -q '^HOME=/home/launcher-test
output="$(DEVSUBSTRATE_REMOTE=github bash "$ROOT/linuxCurlScripts.sh" 4 qca9377)"
grep -q '^QCA9377_STAGE:apply$' <<< "$output"
grep -q 'raw.githubusercontent.com/bitzzdev/devSubstrate/dev/network/wifi/scripts/qca9377-powersave-fix.sh$' "$CURL_URL_LOG"

: > "$CURL_URL_LOG"
set +e
output="$(bash "$ROOT/androidCurlScripts.sh" 2 all 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q '^SHOPPING_STAGE$' <<< "$output"
grep -q '^HOTSPOT_STAGE$' <<< "$output"
grep -q 'android/scripts/manage-shopping-traffic.sh$' "$CURL_URL_LOG"
grep -q 'network/scripts/hotspot-background-traffic-control.sh$' "$CURL_URL_LOG"

set +e
output="$(CURL_FAIL=1 bash "$ROOT/linuxCurlScripts.sh" 2 wifi 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q 'failed to fetch implementation script: network/scripts/metered-connection-control.sh' <<< "$output"
grep -q 'https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/network/scripts/metered-connection-control.sh' <<< "$output"

echo "PASS: GitLab default, GitHub override, Wi-Fi metering route, QCA9377 route, Android aggregate execution, and fetch failure reporting."
 <<< "$output"

: > "$CURL_URL_LOG"
output="$(DEVSUBSTRATE_REMOTE=github bash "$ROOT/linuxCurlScripts.sh" 4 qca9377)"
grep -q '^QCA9377_STAGE:apply$' <<< "$output"
grep -q 'raw.githubusercontent.com/bitzzdev/devSubstrate/dev/network/wifi/scripts/qca9377-powersave-fix.sh$' "$CURL_URL_LOG"

: > "$CURL_URL_LOG"
set +e
output="$(bash "$ROOT/androidCurlScripts.sh" 2 all 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q '^SHOPPING_STAGE$' <<< "$output"
grep -q '^HOTSPOT_STAGE$' <<< "$output"
grep -q 'android/scripts/manage-shopping-traffic.sh$' "$CURL_URL_LOG"
grep -q 'network/scripts/hotspot-background-traffic-control.sh$' "$CURL_URL_LOG"

set +e
output="$(CURL_FAIL=1 bash "$ROOT/linuxCurlScripts.sh" 2 wifi 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -q 'failed to fetch implementation script: network/scripts/metered-connection-control.sh' <<< "$output"
grep -q 'https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/network/scripts/metered-connection-control.sh' <<< "$output"

echo "PASS: GitLab default, GitHub override, Wi-Fi metering route, QCA9377 route, Android aggregate execution, and fetch failure reporting."
