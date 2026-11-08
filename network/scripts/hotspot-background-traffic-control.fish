#!/usr/bin/env fish
#
# hotspot-background-traffic-control.fish: Fish script to restrict or restore
# background traffic for third-party Android apps during hotspot sessions.
#
# Preserves WhatsApp, Telegram, Signal, and hotspot routing.
#
# Usage:
#   ./hotspot-background-traffic-control.fish apply   # Restricts background data
#   ./hotspot-background-traffic-control.fish revert  # Restores default background states
#   ./hotspot-background-traffic-control.fish status  # Displays blacklist and data saver state
#

set -l WHITELIST \
    com.whatsapp \
    org.telegram.messenger \
    org.thoughtcrime.securesms \
    com.google.android.gms

function check_adb
    if not command -v adb >/dev/null 2>&1
        echo "Error: adb command not found. Install Android platform-tools." >&2
        return 1
    end

    if not adb get-state >/dev/null 2>&1
        echo "Error: No authorized ADB device detected. Connect phone and enable USB debugging." >&2
        return 1
    end
    return 0
end

function is_whitelisted -a pkg
    for w in $WHITELIST
        if test "$pkg" = "$w"
            return 0
        end
    end
    return 1
end

function status_restrictions
    echo "=== Current Network Policy Blacklist ==="
    adb shell cmd netpolicy list restrict-background-blacklist 2>/dev/null; or echo "Empty or unavailable."
    echo ""
    echo "=== Data Saver State ==="
    adb shell cmd netpolicy get restrict-background 2>/dev/null; or echo "Unavailable."
end

function apply_restrictions
    echo "Ensuring global Data Saver remains off so hotspot functions..."
    adb shell cmd netpolicy set restrict-background false

    echo "Optimizing third-party application background limits..."
    set -l pkgs (adb shell pm list packages -3 2>/dev/null | string replace "package:" "" | string trim)

    for pkg in $pkgs
        test -z "$pkg"; and continue

        if is_whitelisted "$pkg"
            echo "Skipping whitelisted essential messenger: $pkg"
            continue
        end

        set -l raw (adb shell cmd package list packages -U $pkg 2>/dev/null)
        set -l uid (string match -r 'uid:([0-9]+)' $raw | tail -n 1)

        if test -n "$uid"
            adb shell cmd netpolicy add restrict-background-blacklist $uid >/dev/null 2>&1; or true
            adb shell cmd appops set $pkg RUN_IN_BACKGROUND ignore >/dev/null 2>&1; or true
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1; or true
            adb shell cmd usagestats set-app-standby-bucket $pkg restricted >/dev/null 2>&1; or true
            echo "Restricted: $pkg (UID: $uid)"
        end
    end

    echo "Done. Background data restricted while hotspot remains active."
end

function revert_restrictions
    echo "Restoring third-party packages to Android defaults..."
    adb shell cmd netpolicy set restrict-background false

    set -l pkgs (adb shell pm list packages -3 2>/dev/null | string replace "package:" "" | string trim)

    for pkg in $pkgs
        test -z "$pkg"; and continue

        set -l raw (adb shell cmd package list packages -U $pkg 2>/dev/null)
        set -l uid (string match -r 'uid:([0-9]+)' $raw | tail -n 1)

        if test -n "$uid"
            adb shell cmd netpolicy remove restrict-background-blacklist $uid >/dev/null 2>&1; or true
            adb shell cmd appops set $pkg RUN_IN_BACKGROUND default >/dev/null 2>&1; or true
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND default >/dev/null 2>&1; or true
            adb shell cmd usagestats set-app-standby-bucket $pkg active >/dev/null 2>&1; or true
            echo "Restored: $pkg (UID: $uid)"
        end
    end

    echo "Done. All packages restored to default states."
end

if not check_adb
    exit 1
end

set -l action $argv[1]

switch "$action"
    case "apply"
        apply_restrictions
    case "revert"
        revert_restrictions
    case "status"
        status_restrictions
    case '*'
        echo "Usage: "(status filename)" {apply|revert|status}"
        exit 1
end
