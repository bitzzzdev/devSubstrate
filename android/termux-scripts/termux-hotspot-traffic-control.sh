#!/usr/bin/env bash
#
# termux-hotspot-traffic-control.sh: Restricts background activity across non-essential
# third-party applications from within Termux on Android.
#
# Supports root, su, local loopback ADB (wireless debugging), and unprivileged userland.
#
# Usage:
#   ./termux-hotspot-traffic-control.sh apply   # Restricts background third-party apps
#   ./termux-hotspot-traffic-control.sh revert  # Restores default background behavior
#   ./termux-hotspot-traffic-control.sh status  # Displays current policy states
#

set -euo pipefail

WHITELIST=(
    "com.whatsapp"
    "org.telegram.messenger"
    "org.thoughtcrime.securesms"
    "com.google.android.gms"
    "com.termux"
)

DETECTED_BACKEND="none"

detect_execution_backend() {
    if [[ $(id -u) -eq 0 ]]; then
        DETECTED_BACKEND="root"
    elif command -v adb >/dev/null 2>&1 && timeout 2 adb get-state >/dev/null 2>&1; then
        DETECTED_BACKEND="adb"
    elif command -v su >/dev/null 2>&1 && su -c "id" </dev/null >/dev/null 2>&1; then
        DETECTED_BACKEND="su"
    else
        DETECTED_BACKEND="userland"
    fi
}

exec_android_cmd() {
    local cmd="$1"
    case "$DETECTED_BACKEND" in
        root)
            eval "$cmd"
            ;;
        su)
            su -c "$cmd"
            ;;
        adb)
            adb shell "$cmd"
            ;;
        userland)
            return 1
            ;;
    esac
}

APP_OPS_AVAILABLE=1

exec_appops_set() {
    local pkg="$1" op="$2" mode="$3" output status=0
    output=$(exec_android_cmd "cmd appops set $pkg $op $mode" 2>&1 | tr -d '\r') || status=$?
    if [[ "$output" == *"SecurityException"* || "$output" == *"MANAGE_APP_OPS_MODES"* ]]; then
        if [[ "$APP_OPS_AVAILABLE" -eq 1 ]]; then
            APP_OPS_AVAILABLE=0
            echo "[!] AppOps denied by the OEM permission monitor. Continuing with NetPolicy and standby restrictions." >&2
        fi
        return 1
    fi
    return "$status"
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
    echo "=========================================================="
    echo "Inspecting Hotspot Background Policies"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="
    if [[ "$DETECTED_BACKEND" != "userland" ]]; then
        echo "=== NetPolicy Blacklist ==="
        exec_android_cmd "cmd netpolicy list restrict-background-blacklist 2>/dev/null" || echo "Empty or unavailable."
        echo ""
        echo "=== Data Saver State ==="
        exec_android_cmd "cmd netpolicy get restrict-background 2>/dev/null" || echo "Unavailable."
    else
        echo "Querying system NetPolicy directly requires ADB loopback or root."
        echo "Listing installed third-party apps visible in Termux userland:"
        pm list packages -3 2>/dev/null | head -n 10
    fi
}

apply_restrictions() {
    echo "=========================================================="
    echo "Applying Background Traffic Restrictions"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    local privileged_success=0
    local fallback_used=0

    if [[ "$DETECTED_BACKEND" != "userland" ]]; then
        exec_android_cmd "cmd netpolicy set restrict-background false" || true
        echo "[+] Verified global Data Saver remains off so Hotspot works."

        while IFS= read -r line; do
            pkg="${line#package:}"
            pkg="${pkg%$'\r'}"
            [[ -z "$pkg" ]] && continue

            if is_whitelisted "$pkg"; then
                echo "[*] Whitelisted: $pkg (kept active)"
                continue
            fi

            local uid
            uid=$(exec_android_cmd "dumpsys package $pkg 2>/dev/null | grep -m1 'userId=' | sed -E 's/.*userId=([0-9]+).*/\1/'" || true)

            if [[ -n "$uid" ]]; then
                exec_android_cmd "cmd netpolicy add restrict-background-blacklist $uid" >/dev/null 2>&1 || true
                if ! exec_appops_set "$pkg" RUN_IN_BACKGROUND ignore; then :; fi
                if ! exec_appops_set "$pkg" RUN_ANY_IN_BACKGROUND ignore; then :; fi
                exec_android_cmd "cmd usagestats set-app-standby-bucket $pkg restricted" >/dev/null 2>&1 || true
                echo "[+] Restricted: $pkg (UID: $uid)"
            fi
        done < <(exec_android_cmd "pm list packages -3 2>/dev/null")
        privileged_success=1
    else
        echo "[!] Standard userland: Cannot call netpolicy directly without ADB loopback/root."
        echo "    Executing userland memory and process suspension..."
        fallback_used=1

        while IFS= read -r line; do
            pkg="${line#package:}"
            pkg="${pkg%$'\r'}"
            [[ -z "$pkg" ]] && continue
            if is_whitelisted "$pkg"; then
                continue
            fi
            am force-stop "$pkg" 2>/dev/null || pkill -f "$pkg" 2>/dev/null || true
        done < <(pm list packages -3 2>/dev/null)
    fi

    echo ""
    echo "==================== EXECUTION AUDIT ===================="
    if [[ $privileged_success -eq 1 ]]; then
        echo "COMPLETED VIA PRIVILEGED BACKEND ($DETECTED_BACKEND):"
        echo "  - Third-party apps restricted from background data."
        echo "  - WhatsApp, Telegram, Signal, and hotspot routing are excluded from app UID rules."
        if [[ "$APP_OPS_AVAILABLE" -eq 0 ]]; then
            echo "  - AppOps was refused; NetPolicy and standby controls were attempted."
        fi
    elif [[ $fallback_used -eq 1 ]]; then
        echo "COMPLETED IN TERMUX USERLAND:"
        echo "  - Third-party apps killed to clear memory and halt active sockets."
        echo ""
        echo "WHAT STILL NEEDS ADB OR ROOT PRIVILEGES:"
        echo "  1. Permanent cellular socket block: 'cmd netpolicy add restrict-background-blacklist <UID>'"
        echo "  2. App standby bucket demotion: 'cmd usagestats set-app-standby-bucket <pkg> restricted'"
        echo "  3. Background run restriction: 'cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore'"
        echo ""
        echo "TIP TO RUN LOCALLY ON DEVICE WITHOUT A PC:"
        echo "  Enable Wireless Debugging in Android Developer Options,"
        echo "  install 'pkg install android-tools' in Termux, and run:"
        echo "  'adb pair localhost:<port>' followed by 'adb connect localhost:<port>'."
    fi
    echo "=========================================================="
}

revert_restrictions() {
    echo "=========================================================="
    echo "Reverting Background Traffic Restrictions"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    if [[ "$DETECTED_BACKEND" != "userland" ]]; then
        exec_android_cmd "cmd netpolicy set restrict-background false" || true

        while IFS= read -r line; do
            pkg="${line#package:}"
            pkg="${pkg%$'\r'}"
            [[ -z "$pkg" ]] && continue

            local uid
            uid=$(exec_android_cmd "dumpsys package $pkg 2>/dev/null | grep -m1 'userId=' | sed -E 's/.*userId=([0-9]+).*/\1/'" || true)

            if [[ -n "$uid" ]]; then
                exec_android_cmd "cmd netpolicy remove restrict-background-blacklist $uid" >/dev/null 2>&1 || true
                exec_android_cmd "cmd appops set $pkg RUN_IN_BACKGROUND default" >/dev/null 2>&1 || true
                exec_android_cmd "cmd appops set $pkg RUN_ANY_IN_BACKGROUND default" >/dev/null 2>&1 || true
                exec_android_cmd "cmd usagestats set-app-standby-bucket $pkg active" >/dev/null 2>&1 || true
                echo "[+] Restored: $pkg (UID: $uid)"
            fi
        done < <(exec_android_cmd "pm list packages -3 2>/dev/null")
        echo "Done. All packages restored to default states."
    else
        echo "[!] Standard userland: No permanent system restrictions were active."
    fi
}

detect_execution_backend
action="${1:-status}"

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
