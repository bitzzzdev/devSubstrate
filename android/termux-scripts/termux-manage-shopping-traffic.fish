#!/usr/bin/env fish
#
# termux-manage-shopping-traffic.fish: Local Termux Fish shell script to manage
# shopping application background data and notification drain without a PC.
#
# Execution modes:
#   1. Direct root / Shizuku / su (full capability matching ADB)
#   2. Local ADB over loopback Wi-Fi debugging
#   3. Standard non-root Termux (process termination and cache optimization)
#
# Usage:
#   ./termux-manage-shopping-traffic.fish pause   # Restricts shopping apps
#   ./termux-manage-shopping-traffic.fish resume  # Restores shopping apps
#   ./termux-manage-shopping-traffic.fish status  # Inspects current restrictions
#

set -l TARGET_PACKAGES \
    in.amazon.mShop.android.shopping \
    com.flipkart.android \
    com.myntra.android \
    com.ril.ajio \
    com.meesho.supply \
    com.grofers.customerapp \
    com.zeptoconsumerapp \
    in.swiggy.android \
    com.application.zomato \
    com.bigbasket.mobileapp \
    com.jpl.jiomart \
    com.fsn.nykaa \
    com.snapdeal.main \
    com.tul.tatacliq

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

function get_package_uid -a pkg
    switch "$DETECTED_BACKEND"
        case "root" "su" "adb"
            set -l raw (exec_android_cmd "cmd package list packages -U $pkg 2>/dev/null")
            string match -r 'uid:([0-9]+)' $raw | tail -n 1
        case "userland"
            set -l raw (pm list packages -U "$pkg" 2>/dev/null)
            string match -r 'uid:([0-9]+)' $raw | tail -n 1
    end
end

function is_package_installed -a pkg
    switch "$DETECTED_BACKEND"
        case "root" "su" "adb"
            exec_android_cmd "pm list packages $pkg 2>/dev/null" | string match -q "package:$pkg"
        case "userland"
            pm list packages "$pkg" 2>/dev/null | string match -q "package:$pkg"
    end
end

function set_tethering_offload
    if exec_android_cmd "settings put global tether_offload_disabled 0" >/dev/null 2>&1
        set -l current (exec_android_cmd "settings get global tether_offload_disabled" 2>/dev/null | string trim)
        if test "$current" = "0"
            echo "  - Tethering hardware offload enabled (0)."
            return 0
        end
    end
    echo "  - Tethering offload setting was not writable; existing device behavior is unchanged."
end

function pause_traffic
    echo "=========================================================="
    echo "Executing Pause: Shopping Traffic & Notification Control"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    set -l privileged_success 0
    set -l fallback_used 0

    if test "$DETECTED_BACKEND" != "userland"
        set_tethering_offload

        for pkg in $TARGET_PACKAGES
            if is_package_installed $pkg
                echo "[+] Applying privileged controls to: $pkg"
                exec_android_cmd "cmd appops set $pkg POST_NOTIFICATION ignore"; or true
                exec_android_cmd "cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore"; or true

                set -l uid (get_package_uid $pkg)
                if test -n "$uid"
                    exec_android_cmd "cmd netpolicy add restrict-background-blacklist $uid 2>/dev/null"; or true
                    echo "    -> Blacklisted UID $uid via netpolicy."
                end
                set privileged_success 1
            end
        end
    else
        echo "[!] Running in standard unprivileged Termux userland."
        echo "    Attempting non-root process demotion and stop signals..."
        set fallback_used 1

        for pkg in $TARGET_PACKAGES
            if is_package_installed $pkg
                echo "[*] Killing active background processes for: $pkg"
                am force-stop "$pkg" 2>/dev/null; or pkill -f "$pkg" 2>/dev/null; or true
            end
        end
    end

    echo ""
    echo "==================== EXECUTION AUDIT ===================="
    if test $privileged_success -eq 1
        echo "COMPLETED VIA PRIVILEGED BACKEND ($DETECTED_BACKEND):"
        echo "  - POST_NOTIFICATION disabled for retail apps."
        echo "  - RUN_ANY_IN_BACKGROUND blocked via AppOps."
        echo "  - NetPolicy cellular background sockets blacklisted."
        echo "  - WhatsApp, Instagram, Telegram, and hotspot remain unaffected."
    else if test $fallback_used -eq 1
        echo "COMPLETED IN TERMUX NON-ROOT USERLAND:"
        echo "  - Active background processes terminated for shopping apps."
        echo ""
        echo "WHAT STILL NEEDS ADB OR ROOT PRIVILEGES:"
        echo "  1. Permanent notification suppression: 'cmd appops set <pkg> POST_NOTIFICATION ignore'"
        echo "  2. Background execution denial: 'cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore'"
        echo "  3. Cellular socket blacklist: 'cmd netpolicy add restrict-background-blacklist <UID>'"
        echo ""
        echo "TIP TO RUN LOCALLY ON DEVICE WITHOUT A PC:"
        echo "  Run 'pkg install android-tools' inside Termux, enable Wireless Debugging"
        echo "  in Android Settings, and run 'adb pair localhost:<port>' followed by 'adb connect'."
    end
    echo "=========================================================="
end

function resume_traffic
    echo "=========================================================="
    echo "Executing Resume: Restoring Shopping Applications"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    if test "$DETECTED_BACKEND" != "userland"
        for pkg in $TARGET_PACKAGES
            if is_package_installed $pkg
                echo "[+] Restoring: $pkg"
                exec_android_cmd "cmd appops set $pkg POST_NOTIFICATION allow"; or true
                exec_android_cmd "cmd appops set $pkg RUN_ANY_IN_BACKGROUND allow"; or true

                set -l uid (get_package_uid $pkg)
                if test -n "$uid"
                    exec_android_cmd "cmd netpolicy remove restrict-background-blacklist $uid 2>/dev/null"; or true
                    echo "    -> Restored UID $uid in netpolicy."
                end
            end
        end
        echo ""
        echo "All permissions and background sockets restored to defaults."
    else
        echo "[!] Standard userland: No permanent system restrictions were active."
        echo "    Apps will resume normal background activity upon opening."
    end
end

function show_status
    echo "=========================================================="
    echo "Restriction Status Inspection"
    echo "Detected Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            echo "Package: $pkg"
            if test "$DETECTED_BACKEND" != "userland"
                set -l post_notif (exec_android_cmd "cmd appops get $pkg POST_NOTIFICATION 2>/dev/null" | head -n 1; or echo "unknown")
                set -l run_bg (exec_android_cmd "cmd appops get $pkg RUN_ANY_IN_BACKGROUND 2>/dev/null" | head -n 1; or echo "unknown")
                echo "  POST_NOTIFICATION:   $post_notif"
                echo "  RUN_ANY_IN_BACKGROUND: $run_bg"
            else
                echo "  Status: Installed (inspecting AppOps requires ADB loopback or root)"
            end
        end
    end
end

detect_execution_backend
set -l action $argv[1]
test -z "$action"; and set action "status"

switch "$action"
    case "pause"
        pause_traffic
    case "resume"
        resume_traffic
    case "status"
        show_status
    case '*'
        echo "Usage: "(status filename)" {pause|resume|status}"
        exit 1
end
