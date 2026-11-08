#!/usr/bin/env bash
#
# hotspot-background-traffic-control.sh: Restricts or restores background traffic
# for non-essential third-party apps on Android to protect mobile hotspot bandwidth.
#
# Preserves essential messengers (WhatsApp, Telegram, Signal) and hotspot routing.
#
# Usage:
#   ./hotspot-background-traffic-control.sh apply   # Restricts background data on third-party apps
#   ./hotspot-background-traffic-control.sh revert  # Restores default background execution states
#   ./hotspot-background-traffic-control.sh status  # Lists currently restricted packages
#

set -euo pipefail

WHITELIST=(
    "com.whatsapp"
    "org.telegram.messenger"
    "org.thoughtcrime.securesms"
    "com.google.android.gms"
)

check_adb() {
    if ! command -v adb >/dev/null 2>&1; then
        echo "Error: adb command not found. Install Android platform-tools." >&2
        exit 1
    fi

    if ! adb get-state >/dev/null 2>&1; then
        echo "Error: No authorized ADB device detected. Connect phone and enable USB debugging." >&2
        exit 1
    fi
}

is_whitelisted() {
    local pkg="$1"
    for w in "${WHITELIST[@]}"; do
        if [[ "$pkg" == "$w" ]]; then
            return 0
        fi
    done
    return 1
}

status_restrictions() {
    echo "=== Current Network Policy Blacklist ==="
    adb shell cmd netpolicy list restrict-background-blacklist 2>/dev/null || echo "Empty or unavailable."
    echo ""
    echo "=== Data Saver State ==="
    adb shell cmd netpolicy get restrict-background 2>/dev/null || echo "Unavailable."
}

apply_restrictions() {
    echo "Ensuring global Data Saver remains off so hotspot functions..."
    adb shell cmd netpolicy set restrict-background false

    echo "Optimizing third-party application background limits..."
    while IFS= read -r line; do
        pkg="${line#package:}"
        [[ -z "$pkg" ]] && continue

        if is_whitelisted "$pkg"; then
            echo "Skipping whitelisted essential messenger: $pkg"
            continue
        fi

        uid=$(adb shell dumpsys package "$pkg" 2>/dev/null | grep -m1 "userId=" | sed -E 's/.*userId=([0-9]+).*/\1/' || true)

        if [[ -n "$uid" ]]; then
            adb shell cmd netpolicy add restrict-background-blacklist "$uid" >/dev/null 2>&1 || true
            adb shell cmd appops set "$pkg" RUN_IN_BACKGROUND ignore >/dev/null 2>&1 || true
            adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1 || true
            adb shell cmd usagestats set-app-standby-bucket "$pkg" restricted >/dev/null 2>&1 || true
            echo "Restricted: $pkg (UID: $uid)"
        fi
    done < <(adb shell pm list packages -3 2>/dev/null)

    echo "Done. Background data restricted while hotspot remains active."
}

revert_restrictions() {
    echo "Restoring third-party packages to Android defaults..."
    adb shell cmd netpolicy set restrict-background false

    while IFS= read -r line; do
        pkg="${line#package:}"
        [[ -z "$pkg" ]] && continue

        uid=$(adb shell dumpsys package "$pkg" 2>/dev/null | grep -m1 "userId=" | sed -E 's/.*userId=([0-9]+).*/\1/' || true)

        if [[ -n "$uid" ]]; then
            adb shell cmd netpolicy remove restrict-background-blacklist "$uid" >/dev/null 2>&1 || true
            adb shell cmd appops set "$pkg" RUN_IN_BACKGROUND default >/dev/null 2>&1 || true
            adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND default >/dev/null 2>&1 || true
            adb shell cmd usagestats set-app-standby-bucket "$pkg" active >/dev/null 2>&1 || true
            echo "Restored: $pkg (UID: $uid)"
        fi
    done < <(adb shell pm list packages -3 2>/dev/null)

    echo "Done. All packages restored to default states."
}

action="${1:-}"

check_adb

case "$action" in
    apply)
        apply_restrictions
        ;;
    revert)
        revert_restrictions
        ;;
    status)
        status_restrictions
        ;;
    *)
        echo "Usage: $0 {apply|revert|status}"
        exit 1
        ;;
esac
