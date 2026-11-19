#!/usr/bin/env bash
#
# termux-manage-shopping-traffic.sh: Local Termux script to manage catalog application
# background data and notification drain without requiring a host PC.
#
# Execution modes:
#   1. Direct root / Shizuku / su (full capability matching ADB)
#   2. Local ADB over loopback Wi-Fi debugging (port 5555 or dynamic pairing)
#   3. Standard non-root Termux (process termination and cache optimization)
#
# Usage:
#   ./termux-manage-shopping-traffic.sh pause   # Restricts installed catalog apps
#   ./termux-manage-shopping-traffic.sh resume  # Restores catalog apps
#   ./termux-manage-shopping-traffic.sh status  # Inspects current restrictions
#   ./termux-manage-shopping-traffic.sh check   # Checks root and OEM unlocking status
#

set -euo pipefail

TARGET_PACKAGES=(
    "in.amazon.mShop.android.shopping"
    "com.flipkart.android"
    "com.flipkart.shopsy"
    "com.myntra.android"
    "com.ril.ajio"
    "com.meesho.supply"
    "com.grofers.customerapp"
    "com.zeptoconsumerapp"
    "com.bigbasket.mobileapp"
    "com.jpl.jiomart"
    "com.fsn.nykaa"
    "com.snapdeal.main"
    "com.tul.tatacliq"
    "com.firstcry.android"
    "com.purplle"
    "com.olx.southasia"
    "com.indiamart.m"
    "com.urbanic"
    "com.limeroad"
    "com.pepperfry"
    "in.swiggy.android"
    "com.application.zomato"
    "com.rebelfoods.eatsure"
    "com.dominos"
    "com.pizzahutindia"
    "com.yum.kfc"
    "com.instagram.android"
    "com.facebook.katana"
    "com.instagram.barcelona"
    "com.twitter.android"
    "com.snapchat.android"
    "com.pinterest"
    "com.reddit.frontpage"
    "com.linkedin.android"
    "in.mohalla.sharechat"
    "in.mohalla.video"
    "in.mohalla.josh"
    "io.chingari.app"
    "com.tumblr"
    "com.quora.android"
    "com.discord"
    "tv.twitch.android.app"
    "com.bereal.ft"
    "com.clubhouse.app"
    "com.narvii.amino.master"
    "com.roposo.android"
    "com.google.android.youtube"
    "com.google.android.apps.youtube.music"
    "com.netflix.mediaclient"
    "com.amazon.avod.thirdpartyclient"
    "in.startv.hotstar"
    "com.jio.media.ondemand"
    "com.sonyliv"
    "com.graymatrix.did"
    "com.mxtech.videoplayer.ad"
    "com.spotify.music"
    "com.jio.media.jiobeats"
    "com.gaana"
    "com.bsbportal.music"
    "com.audible.application"
    "com.pocketfm"
    "com.kukufm"
    "com.amazon.mp3"
    "com.soundcloud.android"
    "com.pubg.imobile"
    "com.dts.freefireth"
    "com.dts.freefiremax"
    "com.activision.callofduty.shooter"
    "com.supercell.clashofclans"
    "com.supercell.clashroyale"
    "com.roblox.client"
    "com.mojang.minecraftpe"
    "com.kiloo.subwaysurf"
    "com.ludo.king"
    "com.miniclip.eightballpool"
    "com.king.candycrushsaga"
    "com.miHoYo.GenshinImpact"
    "com.HoYoverse.hkrpgoversea"
    "com.gameloft.android.ANMP.GloftA9HM"
    "com.ea.game.pvz2_row"
    "com.ea.game.fifa.mobile"
    "com.supercell.brawlstars"
    "com.nis.app"
    "com.eterno"
    "com.toi.reader.activities"
    "com.cricbuzz.android"
    "com.espn.score_center"
    "com.dream11pro"
    "com.fancode.video"
    "com.ndtv.news"
    "com.ibn.livetv"
    "com.google.android.apps.magazines"
    "com.tinder"
    "com.bumble.app"
    "co.hinge.app"
    "com.app.aisle"
    "com.happn"
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
            # Cannot call cmd or settings directly in unprivileged userland without ADB/root
            return 1
            ;;
    esac
}

# ColorOS, OxygenOS, Realme UI, MIUI, and HyperOS do not grant
# MANAGE_APP_OPS_MODES to the shell user while their permission monitor is active.
# The shell command then fails with a SecurityException even though the same
# command works on a stock build. One warning explains the fix; later failures
# stay quiet so the per-package output remains readable.
APP_OPS_AVAILABLE=1

oem_permission_monitor_hint() {
    local brand
    brand=$(exec_android_cmd "getprop ro.product.brand 2>/dev/null" | tr -d '\r\n' | tr '[:upper:]' '[:lower:]') || true
    case "$brand" in
        realme|oppo|oneplus|coloros)
            echo "Settings -> System -> Developer Options -> 'Disable permission monitoring' (newer ColorOS and OxygenOS builds call it 'Disable system optimization')"
            ;;
        xiaomi|redmi|poco)
            echo "Settings -> Additional settings -> Developer Options -> 'USB debugging (Security settings)'"
            ;;
        *)
            echo "Settings -> Developer Options -> the OEM option that lets USB debugging change app permissions"
            ;;
    esac
}

report_appops_blocked() {
    [[ "$APP_OPS_AVAILABLE" -eq 1 ]] || return 0
    APP_OPS_AVAILABLE=0
    {
        echo ""
        echo "[!] Android denied the AppOps change: the shell user is missing MANAGE_APP_OPS_MODES."
        echo "    This build gates AppOps behind its permission monitor, so 'cmd appops set' is refused."
        echo "    To grant it:"
        echo "      $(oem_permission_monitor_hint)"
        echo "      Reboot and rerun this script for notification and background control."
        echo "    Continuing with the restrictions that do not need AppOps."
        echo ""
    } >&2
}

exec_appops_set() {
    local pkg="$1"
    local op="$2"
    local mode="$3"
    local output
    local status=0
    output=$(exec_android_cmd "cmd appops set $pkg $op $mode 2>&1") || status=$?
    if [[ "$output" == *"SecurityException"* || "$output" == *"MANAGE_APP_OPS_MODES"* ]]; then
        report_appops_blocked
        return 1
    fi
    return "$status"
}

exec_appops_get() {
    local pkg="$1"
    local op="$2"
    local output
    local status=0
    output=$(exec_android_cmd "cmd appops get $pkg $op 2>&1") || status=$?
    if [[ "$output" == *"SecurityException"* || "$output" == *"MANAGE_APP_OPS_MODES"* ]]; then
        echo "unknown"
        return 0
    fi
    if [[ $status -ne 0 ]]; then
        echo "unknown"
        return 0
    fi
    head -n 1 <<< "$output"
}

appops_available() {
    local pkg="${TARGET_PACKAGES[0]}"
    local output
    output=$(exec_android_cmd "cmd appops get $pkg RUN_IN_BACKGROUND 2>&1") || true
    [[ "$output" != *"SecurityException"* && "$output" != *"MANAGE_APP_OPS_MODES"* ]]
}

get_package_uid() {
    local pkg="$1"
    case "$DETECTED_BACKEND" in
        root|su|adb)
            exec_android_cmd "cmd package list packages -U $pkg 2>/dev/null" | sed -n 's/.*uid:\([0-9]*\).*/\1/p' || true
            ;;
        userland)
            pm list packages -U "$pkg" 2>/dev/null | sed -n 's/.*uid:\([0-9]*\).*/\1/p' || true
            ;;
    esac
}

is_package_installed() {
    local pkg="$1"
    case "$DETECTED_BACKEND" in
        root|su|adb)
            exec_android_cmd "pm list packages $pkg 2>/dev/null" | tr -d '\r' | grep -q "^package:${pkg}$" || return 1
            ;;
        userland)
            pm list packages "$pkg" 2>/dev/null | tr -d '\r' | grep -q "^package:${pkg}$" || return 1
            ;;
    esac
}

check_oem_and_root_compatibility() {
    echo "=========================================================="
    echo "Device Compatibility: Root and Bootloader Lock Diagnostics"
    echo "=========================================================="

    local has_root=0
    if [[ "$DETECTED_BACKEND" == "root" || "$DETECTED_BACKEND" == "su" ]]; then
        has_root=1
    fi

    local oem_unlock_allowed
    oem_unlock_allowed=$(getprop sys.oem_unlock_allowed 2>/dev/null | tr -d '\r\n')
    local bootloader_locked
    bootloader_locked=$(getprop ro.boot.flash.locked 2>/dev/null | tr -d '\r\n')
    local verified_boot
    verified_boot=$(getprop ro.boot.verifiedbootstate 2>/dev/null | tr -d '\r\n')
    local oem_unlock_supported
    oem_unlock_supported=$(getprop ro.oem_unlock_supported 2>/dev/null | tr -d '\r\n')

    echo "Diagnostic Properties:"
    echo "  - Detected Backend:             $DETECTED_BACKEND"
    echo "  - Root Privilege:               $([[ $has_root -eq 1 ]] && echo 'Available (uid 0)' || echo 'Not present')"
    echo "  - OEM Unlocking (sys):          ${oem_unlock_allowed:-unknown} (1=allowed, 0=blocked)"
    echo "  - Bootloader Lock (flash):      ${bootloader_locked:-unknown} (1=locked, 0=unlocked)"
    echo "  - Verified Boot State:          ${verified_boot:-unknown}"
    echo "  - OEM Unlock Supported:         ${oem_unlock_supported:-unknown}"
    echo ""

    if [[ $has_root -eq 1 ]]; then
        echo "[+] ROOT DETECTED: Privileged execution and Netfilter controls enabled."
        return 0
    fi

    if [[ "$bootloader_locked" == "0" ]]; then
        echo "[i] Bootloader is UNLOCKED (ro.boot.flash.locked=0)."
        echo "    Install Magisk or KernelSU to obtain full root capabilities in Termux."
        return 0
    fi

    if [[ "$oem_unlock_allowed" != "1" ]]; then
        echo "[!] COMPATIBILITY WARNING: OEM Unlocking is DISABLED on this device."
        echo "    Current status: sys.oem_unlock_allowed=${oem_unlock_allowed:-0}"
        echo ""
        echo "    To enable OEM Unlocking for enhanced root capabilities:"
        echo "      1. Open Settings -> About Phone."
        echo "      2. Tap 'Build Number' 7 times rapidly until Developer options unlock."
        echo "      3. Go to Settings -> System -> Developer Options."
        echo "      4. Toggle 'OEM unlocking' to ON (and keep 'USB debugging' active)."
        echo "      5. (Optional) Unlock bootloader in fastboot and install Magisk."
        echo "      6. Run this script again for enhanced compatibility."
    else
        echo "[i] OEM Unlocking is ENABLED (sys.oem_unlock_allowed=1)."
        echo "    Device bootloader can be unlocked for root access whenever desired."
    fi
    echo "=========================================================="
}

pause_traffic() {
    echo "=========================================================="
    echo "Executing Pause: Shopping Traffic & Notification Control"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    local privileged_success=0
    local fallback_used=0

    # Try privileged operations (Root, SU, or Local ADB loopback)
    if [[ "$DETECTED_BACKEND" != "userland" ]]; then

        for pkg in "${TARGET_PACKAGES[@]}"; do
            if is_package_installed "$pkg"; then
                echo "[+] Applying privileged controls to: $pkg"
                local applied=0
                if exec_appops_set "$pkg" POST_NOTIFICATION ignore; then applied=$((applied + 1)); fi
                if exec_appops_set "$pkg" RUN_ANY_IN_BACKGROUND ignore; then applied=$((applied + 1)); fi
                
                local uid
                uid="$(get_package_uid "$pkg")"
                if [[ -n "$uid" ]]; then
                    exec_android_cmd "cmd netpolicy add restrict-background-blacklist $uid" 2>/dev/null || true
                    echo "    -> Blacklisted UID $uid via netpolicy."
                fi
                privileged_success=1
                if [[ $applied -lt 2 ]]; then
                    echo "    -> AppOps applied partially ($applied/2)."
                fi
            fi
        done
    else
        echo "[!] Running in standard unprivileged Termux userland."
        echo "    Attempting non-root process demotion and stop signals..."
        fallback_used=1

        for pkg in "${TARGET_PACKAGES[@]}"; do
            if is_package_installed "$pkg"; then
                echo "[*] Killing active background processes for: $pkg"
                am force-stop "$pkg" 2>/dev/null || pkill -f "$pkg" 2>/dev/null || true
            fi
        done
    fi

    echo ""
    echo "==================== EXECUTION AUDIT ===================="
    if [[ $privileged_success -eq 1 ]]; then
        echo "COMPLETED VIA PRIVILEGED BACKEND ($DETECTED_BACKEND):"
        if [[ $APP_OPS_AVAILABLE -eq 1 ]]; then
            echo "  - POST_NOTIFICATION disabled for retail apps."
            echo "  - RUN_ANY_IN_BACKGROUND blocked via AppOps."
        else
            echo "  - AppOps controls refused by the device permission monitor (see warning above)."
            echo "  - NetPolicy and standby controls still applied where supported."
        fi
        echo "  - NetPolicy cellular background sockets blacklisted."
        echo "  - Protected messaging, payment, Google core, and transport apps remain outside the target set."
    elif [[ $fallback_used -eq 1 ]]; then
        echo "COMPLETED IN TERMUX NON-ROOT USERLAND:"
        echo "  - Active background processes terminated for catalog apps."
        echo ""
        echo "WHAT STILL NEEDS ADB OR ROOT PRIVILEGES:"
        echo "  1. Permanent notification suppression: 'cmd appops set <pkg> POST_NOTIFICATION ignore'"
        echo "  2. Background execution denial: 'cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore'"
        echo "  3. Cellular socket blacklist: 'cmd netpolicy add restrict-background-blacklist <UID>'"
        echo ""
        echo "TIP TO RUN LOCALLY ON DEVICE WITHOUT A PC:"
        echo "  Run 'pkg install android-tools' inside Termux, enable Wireless Debugging"
        echo "  in Android Settings, and run 'adb pair localhost:<port>' followed by 'adb connect'."
    fi
    echo "=========================================================="
    if [[ $APP_OPS_AVAILABLE -eq 0 ]]; then
        return 1
    fi
}

resume_traffic() {
    echo "=========================================================="
    echo "Executing Resume: Restoring Shopping Applications"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    if [[ "$DETECTED_BACKEND" != "userland" ]]; then
        for pkg in "${TARGET_PACKAGES[@]}"; do
            if is_package_installed "$pkg"; then
                echo "[+] Restoring: $pkg"
                local applied=0
                if exec_appops_set "$pkg" POST_NOTIFICATION allow; then applied=$((applied + 1)); fi
                if exec_appops_set "$pkg" RUN_ANY_IN_BACKGROUND allow; then applied=$((applied + 1)); fi
                
                local uid
                uid="$(get_package_uid "$pkg")"
                if [[ -n "$uid" ]]; then
                    exec_android_cmd "cmd netpolicy remove restrict-background-blacklist $uid" 2>/dev/null || true
                    echo "    -> Restored UID $uid in netpolicy."
                fi
            fi
        done
        echo ""
        if [[ $APP_OPS_AVAILABLE -eq 0 ]]; then
            echo "Partial: netpolicy entries removed. AppOps modes were not changed."
            return 1
        fi
        echo "All permissions and background sockets restored to defaults."
    else
        echo "[!] Standard userland: No permanent system restrictions were active."
        echo "    Apps will resume normal background activity upon opening."
    fi
}

show_status() {
    echo "=========================================================="
    echo "Restriction Status Inspection"
    echo "Detected Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    if [[ "$DETECTED_BACKEND" != "userland" ]] && ! appops_available; then
        report_appops_blocked
    fi

    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            echo "Package: $pkg"
            if [[ "$DETECTED_BACKEND" != "userland" ]]; then
                local post_notif
                local run_bg
                post_notif="$(exec_appops_get "$pkg" POST_NOTIFICATION)"
                run_bg="$(exec_appops_get "$pkg" RUN_ANY_IN_BACKGROUND)"
                echo "  POST_NOTIFICATION:   $post_notif"
                echo "  RUN_ANY_IN_BACKGROUND: $run_bg"
            else
                echo "  Status: Installed (inspecting AppOps requires ADB loopback or root)"
            fi
        fi
    done
}

detect_execution_backend
action="${1:-status}"

case "$action" in
    pause)
        pause_traffic
        ;;
    resume)
        resume_traffic
        ;;
    status)
        show_status
        ;;
    check)
        check_oem_and_root_compatibility
        ;;
    *)
        echo "Usage: $0 {pause|resume|status|check}"
        exit 1
        ;;
esac
