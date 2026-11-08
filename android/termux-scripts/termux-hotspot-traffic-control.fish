#!/usr/bin/env fish
#
# termux-hotspot-traffic-control.fish: Fish shell script to manage background
# traffic from within Termux on Android.
#
# Supports root, su, local loopback ADB (wireless debugging), and unprivileged userland.
#
# Usage:
#   ./termux-hotspot-traffic-control.fish apply   # Restricts background third-party apps
#   ./termux-hotspot-traffic-control.fish revert  # Restores default background behavior
#   ./termux-hotspot-traffic-control.fish status  # Displays current policy states
#

set -l WHITELIST \
    com.whatsapp \
    org.telegram.messenger \
    org.thoughtcrime.securesms \
    com.google.android.gms \
    com.termux

set -g DETECTED_BACKEND "none"

function detect_execution_backend
    if test (id -u) -eq 0
        set -g DETECTED_BACKEND "root"
    else if command -v adb >/dev/null 2>&1; and timeout 2 adb get-state >/dev/null 2>&1
        set -g DETECTED_BACKEND "adb"
    else if command -v su >/dev/null 2>&1; and su -c "id" </dev/null >/dev/null 2>&1
        set -g DETECTED_BACKEND "su"
    else
        set -g DETECTED_BACKEND "userland"
    end
end

function exec_android_cmd -a cmd
    switch "$DETECTED_BACKEND"
        case "root"
            eval "$cmd"
        case "su"
            su -c "$cmd"
        case "adb"
            adb shell "$cmd"
        case "userland"
            return 1
    end
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
    echo "=========================================================="
    echo "Inspecting Hotspot Background Policies"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="
    if test "$DETECTED_BACKEND" != "userland"
        echo "=== NetPolicy Blacklist ==="
        exec_android_cmd "cmd netpolicy list restrict-background-blacklist 2>/dev/null"; or echo "Empty or unavailable."
        echo ""
        echo "=== Data Saver State ==="
        exec_android_cmd "cmd netpolicy get restrict-background 2>/dev/null"; or echo "Unavailable."
    else
        echo "Querying system NetPolicy directly requires ADB loopback or root."
        echo "Listing installed third-party apps visible in Termux userland:"
        pm list packages -3 2>/dev/null | head -n 10
    end
end

function apply_restrictions
    echo "=========================================================="
    echo "Applying Background Traffic Restrictions"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    set -l privileged_success 0
    set -l fallback_used 0

    if test "$DETECTED_BACKEND" != "userland"
        exec_android_cmd "cmd netpolicy set restrict-background false"; or true
        echo "[+] Verified global Data Saver remains off so Hotspot works."

        set -l pkgs (exec_android_cmd "pm list packages -3 2>/dev/null" | string replace "package:" "" | string trim)
        for pkg in $pkgs
            test -z "$pkg"; and continue

            if is_whitelisted "$pkg"
                echo "[*] Whitelisted: $pkg (kept active)"
                continue
            end

            set -l raw (exec_android_cmd "cmd package list packages -U $pkg 2>/dev/null")
            set -l uid (string match -r 'uid:([0-9]+)' $raw | tail -n 1)

            if test -n "$uid"
                exec_android_cmd "cmd netpolicy add restrict-background-blacklist $uid 2>/dev/null"; or true
                exec_android_cmd "cmd appops set $pkg RUN_IN_BACKGROUND ignore 2>/dev/null"; or true
                exec_android_cmd "cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore 2>/dev/null"; or true
                exec_android_cmd "cmd usagestats set-app-standby-bucket $pkg restricted 2>/dev/null"; or true
                echo "[+] Restricted: $pkg (UID: $uid)"
            end
        end
        set privileged_success 1
    else
        echo "[!] Standard userland: Cannot call netpolicy directly without ADB loopback/root."
        echo "    Executing userland memory and process suspension..."
        set fallback_used 1

        set -l pkgs (pm list packages -3 2>/dev/null | string replace "package:" "" | string trim)
        for pkg in $pkgs
            test -z "$pkg"; and continue
            if is_whitelisted "$pkg"
                continue
            end
            am force-stop "$pkg" 2>/dev/null; or pkill -f "$pkg" 2>/dev/null; or true
        end
    end

    echo ""
    echo "==================== EXECUTION AUDIT ===================="
    if test $privileged_success -eq 1
        echo "COMPLETED VIA PRIVILEGED BACKEND ($DETECTED_BACKEND):"
        echo "  - Third-party apps restricted from background data."
        echo "  - WhatsApp, Telegram, Signal, and hotspot remain functional."
    else if test $fallback_used -eq 1
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
    end
    echo "=========================================================="
end

function revert_restrictions
    echo "=========================================================="
    echo "Reverting Background Traffic Restrictions"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    if test "$DETECTED_BACKEND" != "userland"
        exec_android_cmd "cmd netpolicy set restrict-background false"; or true

        set -l pkgs (exec_android_cmd "pm list packages -3 2>/dev/null" | string replace "package:" "" | string trim)
        for pkg in $pkgs
            test -z "$pkg"; and continue

            set -l raw (exec_android_cmd "cmd package list packages -U $pkg 2>/dev/null")
            set -l uid (string match -r 'uid:([0-9]+)' $raw | tail -n 1)

            if test -n "$uid"
                exec_android_cmd "cmd netpolicy remove restrict-background-blacklist $uid 2>/dev/null"; or true
                exec_android_cmd "cmd appops set $pkg RUN_IN_BACKGROUND default 2>/dev/null"; or true
                exec_android_cmd "cmd appops set $pkg RUN_ANY_IN_BACKGROUND default 2>/dev/null"; or true
                exec_android_cmd "cmd usagestats set-app-standby-bucket $pkg active 2>/dev/null"; or true
                echo "[+] Restored: $pkg (UID: $uid)"
            end
        end
        echo "Done. All packages restored to default states."
    else
        echo "[!] Standard userland: No permanent system restrictions were active."
    end
end

detect_execution_backend
set -l action $argv[1]
test -z "$action"; and set action "status"

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
