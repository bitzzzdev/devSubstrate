#!/usr/bin/env bash
#
# manage-shopping-traffic.sh: Selectively pause or resume background data and notifications
# for retail, delivery, and non-essential Android applications via ADB.
#
# Supports smart root and OEM unlocking detection, kernel-level iptables filtering,
# AppOps notification suppression, NetPolicy cellular blacklisting, standby bucketing,
# and UI/Accessibility automation to toggle background data across OEM skins.
#
# Leaves WhatsApp, Instagram, Telegram, Google Play Services, and Wi-Fi Hotspot intact.
#
# Usage:
#   ./manage-shopping-traffic.sh pause         # Restricts shopping apps
#   ./manage-shopping-traffic.sh resume        # Restores shopping apps
#   ./manage-shopping-traffic.sh status        # Inspects current restrictions
#   ./manage-shopping-traffic.sh check         # Checks root and OEM unlocking compatibility
#   ./manage-shopping-traffic.sh automate-ui   # UI automation to toggle background data
#

set -euo pipefail

TARGET_PACKAGES=(
    "in.amazon.mShop.android.shopping"
    "com.flipkart.android"
    "com.myntra.android"
    "com.ril.ajio"
    "com.meesho.supply"
    "com.grofers.customerapp"
    "com.zeptoconsumerapp"
    "in.swiggy.android"
    "com.application.zomato"
    "com.bigbasket.mobileapp"
    "com.jpl.jiomart"
    "com.fsn.nykaa"
    "com.snapdeal.main"
    "com.tul.tatacliq"
)

# Cellular network interfaces across Qualcomm, MediaTek, Exynos, and standard modems
CELLULAR_INTERFACES=("rmnet+" "ccmni+" "pdp+" "wwan+")

# ColorOS, OxygenOS, Realme UI, MIUI, and HyperOS do not grant
# MANAGE_APP_OPS_MODES to the shell user while their permission monitor is active.
# The shell command then fails with a SecurityException even though the same
# command works on a stock build. One warning explains the fix; later failures
# stay quiet so the per-package output remains readable.
APP_OPS_AVAILABLE=1

oem_permission_monitor_hint() {
    local brand
    brand=$(adb shell getprop ro.product.brand 2>/dev/null | tr -d '\r\n' | tr '[:upper:]' '[:lower:]') || true
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
        echo "      Reboot, reconnect ADB, and run this script again for notification and background control."
        echo "    Continuing with the restrictions that do not need AppOps (standby bucket and UID blacklist)."
        echo ""
    } >&2
}

appops_set() {
    local pkg="$1"
    local op="$2"
    local mode="$3"
    local output
    local status=0
    output=$(adb shell cmd appops set "$pkg" "$op" "$mode" 2>&1 | tr -d '\r') || status=$?
    if [[ "$output" == *"SecurityException"* || "$output" == *"MANAGE_APP_OPS_MODES"* ]]; then
        report_appops_blocked
        return 1
    fi
    return "$status"
}

appops_get() {
    local pkg="$1"
    local op="$2"
    local output
    local status=0
    output=$(adb shell cmd appops get "$pkg" "$op" 2>&1 | tr -d '\r') || status=$?
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
    output=$(adb shell cmd appops get "$pkg" RUN_IN_BACKGROUND 2>&1 | tr -d '\r') || true
    [[ "$output" != *"SecurityException"* && "$output" != *"MANAGE_APP_OPS_MODES"* ]]
}

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

check_root() {
    # Check if adb is running as root or su is available with root uid
    if adb shell "id" 2>/dev/null | grep -q "uid=0(root)"; then
        return 0
    fi
    if adb shell "command -v su >/dev/null 2>&1 && su -c id 2>/dev/null" | grep -q "uid=0"; then
        return 0
    fi
    return 1
}

run_as_root() {
    local cmd="$1"
    if adb shell "id" 2>/dev/null | grep -q "uid=0(root)"; then
        adb shell "$cmd"
    else
        adb shell "su -c \"$cmd\""
    fi
}

check_oem_and_root_compatibility() {
    echo "=========================================================="
    echo "Device Compatibility: Root and Bootloader Lock Diagnostics"
    echo "=========================================================="

    local has_root=0
    if check_root; then
        has_root=1
    fi

    local oem_unlock_allowed
    oem_unlock_allowed=$(adb shell getprop sys.oem_unlock_allowed 2>/dev/null | tr -d '\r\n')
    local bootloader_locked
    bootloader_locked=$(adb shell getprop ro.boot.flash.locked 2>/dev/null | tr -d '\r\n')
    local verified_boot
    verified_boot=$(adb shell getprop ro.boot.verifiedbootstate 2>/dev/null | tr -d '\r\n')
    local oem_unlock_supported
    oem_unlock_supported=$(adb shell getprop ro.oem_unlock_supported 2>/dev/null | tr -d '\r\n')

    echo "Diagnostic Properties:"
    echo "  - Root Privilege:               $([[ $has_root -eq 1 ]] && echo 'Available (uid 0)' || echo 'Not present')"
    echo "  - OEM Unlocking (sys):          ${oem_unlock_allowed:-unknown} (1=allowed, 0=blocked)"
    echo "  - Bootloader Lock (flash):      ${bootloader_locked:-unknown} (1=locked, 0=unlocked)"
    echo "  - Verified Boot State:          ${verified_boot:-unknown}"
    echo "  - OEM Unlock Supported:         ${oem_unlock_supported:-unknown}"
    echo ""

    if [[ $has_root -eq 1 ]]; then
        echo "[+] ROOT DETECTED: Full kernel-level iptables socket filtering enabled."
        echo "    Cellular packets will be filtered directly via kernel Netfilter hooks."
        return 0
    fi

    if [[ "$bootloader_locked" == "0" ]]; then
        echo "[i] Bootloader is UNLOCKED (ro.boot.flash.locked=0)."
        echo "    Device has an unlocked bootloader. For maximum compatibility and kernel-level"
        echo "    iptables packet filtering, install Magisk or KernelSU to grant root privileges."
        echo "    Continuing in standard ADB mode (AppOps + NetPolicy + Standby Buckets)..."
        return 0
    fi

    if [[ "$oem_unlock_allowed" != "1" ]]; then
        echo "[!] COMPATIBILITY WARNING: OEM Unlocking is DISABLED on this device."
        echo "    Current status: sys.oem_unlock_allowed=${oem_unlock_allowed:-0}"
        echo ""
        echo "    Why this matters:"
        echo "    Certain customized OEM skins (ColorOS, MIUI, FuntouchOS) occasionally reset"
        echo "    or ignore background NetPolicy blacklists when apps are restarted."
        echo "    Enabling OEM unlocking allows bootloader unlocking and root access, which grants"
        echo "    hardware-level packet dropping via iptables and persistent background isolation."
        echo ""
        echo "    How to enable OEM Unlocking:"
        echo "      1. Open Settings -> About Phone (or 'About Device')."
        echo "      2. Tap 'Build Number' 7 times rapidly until 'You are now a developer' appears."
        echo "      3. Navigate to Settings -> System -> Developer Options."
        echo "      4. Toggle 'OEM unlocking' to ON (and ensure 'USB debugging' remains active)."
        echo "      5. (Optional for root) Unlock bootloader in fastboot mode and flash Magisk."
        echo "      6. Run this script again for enhanced compatibility."
        echo ""
        echo "    Proceeding in standard ADB mode (AppOps + NetPolicy + Standby Buckets)..."
    else
        echo "[i] OEM Unlocking is ENABLED (sys.oem_unlock_allowed=1)."
        echo "    Your bootloader can be unlocked whenever you choose to obtain root access."
        echo "    Proceeding in standard ADB mode (AppOps + NetPolicy + Standby Buckets)..."
    fi
    echo "=========================================================="
}

get_package_uid() {
    local pkg="$1"
    adb shell cmd package list packages -U "$pkg" 2>/dev/null | sed -n 's/.*uid:\([0-9]*\).*/\1/p' || true
}

is_package_installed() {
    local pkg="$1"
    # adb appends CR to every line; strip it or the anchored grep never matches.
    adb shell pm list packages "$pkg" 2>/dev/null | tr -d '\r' | grep -q "^package:${pkg}$"
}

apply_iptables_uid_drop() {
    local uid="$1"
    for iface in "${CELLULAR_INTERFACES[@]}"; do
        run_as_root "iptables -C OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || iptables -I OUTPUT -o $iface -m owner --uid-owner $uid -j DROP" >/dev/null 2>&1 || true
        run_as_root "ip6tables -C OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || ip6tables -I OUTPUT -o $iface -m owner --uid-owner $uid -j DROP" >/dev/null 2>&1 || true
    done
}

remove_iptables_uid_drop() {
    local uid="$1"
    for iface in "${CELLULAR_INTERFACES[@]}"; do
        run_as_root "iptables -D OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || true" >/dev/null 2>&1 || true
        run_as_root "ip6tables -D OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || true" >/dev/null 2>&1 || true
    done
}

# Magisk and KernelSU run every /data/adb/service.d/*.sh as root at the late_start
# service phase. The hook re-applies AppOps, standby bucket, NetPolicy blacklist and
# iptables rules after every reboot so the restrictions survive restarts. The hook is
# deleted by the resume/revert action, or by a factory reset, which wipes /data.
# shellcheck disable=SC2016,SC2028
install_boot_hook() {
    local hook_path="$1"
    local with_post_notification="$2"
    shift 2
    local packages="$*"
    if ! run_as_root "test -d /data/adb/service.d" >/dev/null 2>&1; then
        echo "[i] /data/adb/service.d is missing. Install Magisk or KernelSU to persist restrictions across reboots."
        return 1
    fi
    local hook_tmp
    hook_tmp="$(mktemp /tmp/devsubstrate-boot-hook.XXXXXX.sh)"
    {
        echo '#!/system/bin/sh'
        echo '# devSubstrate boot hook. Re-applies background restrictions after reboot.'
        echo '# Managed by this script; removed by its resume/revert action.'
        echo "PACKAGES=\"$packages\""
        echo 'INTERFACES="rmnet+ ccmni+ pdp+ wwan+"'
        echo 'for pkg in $PACKAGES; do'
        echo '    uid=$(cmd package list packages -U "$pkg" 2>/dev/null | sed -n "s/.*uid:\([0-9]*\).*/\1/p" | head -n 1)'
        echo '    [ -z "$uid" ] && continue'
        if [ "$with_post_notification" = "1" ]; then
            echo '    cmd appops set "$pkg" POST_NOTIFICATION ignore 2>/dev/null'
        fi
        echo '    cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore 2>/dev/null'
        echo '    cmd appops set "$pkg" RUN_IN_BACKGROUND ignore 2>/dev/null'
        echo '    cmd usagestats set-app-standby-bucket "$pkg" restricted 2>/dev/null'
        echo '    cmd netpolicy add restrict-background-blacklist "$uid" 2>/dev/null'
        echo '    for iface in $INTERFACES; do'
        echo '        iptables -C OUTPUT -o "$iface" -m owner --uid-owner "$uid" -j DROP 2>/dev/null || iptables -I OUTPUT -o "$iface" -m owner --uid-owner "$uid" -j DROP 2>/dev/null'
        echo '        ip6tables -C OUTPUT -o "$iface" -m owner --uid-owner "$uid" -j DROP 2>/dev/null || ip6tables -I OUTPUT -o "$iface" -m owner --uid-owner "$uid" -j DROP 2>/dev/null'
        echo '    done'
        echo 'done'
    } > "$hook_tmp"
    local remote
    remote="/data/local/tmp/$(basename "$hook_path")"
    if ! adb push "$hook_tmp" "$remote" >/dev/null 2>&1; then
        rm -f "$hook_tmp"
        echo "[!] Could not push boot hook to device." >&2
        return 1
    fi
    if run_as_root "cp $remote $hook_path && chmod 755 $hook_path && rm -f $remote" >/dev/null 2>&1; then
        echo "[+] Boot hook installed at $hook_path. It survives reboots until the resume/revert action runs."
    else
        rm -f "$hook_tmp" "$remote"
        echo "[!] Could not install boot hook at $hook_path." >&2
        return 1
    fi
    rm -f "$hook_tmp"
}

remove_boot_hook() {
    local hook_path="$1"
    local remote
    remote="/data/local/tmp/$(basename "$hook_path")"
    run_as_root "rm -f $hook_path $remote" >/dev/null 2>&1 || true
    echo "[i] Boot hook removed if present: $hook_path"
}

pause_traffic() {
    echo "Applying selective background and notification restrictions..."
    check_oem_and_root_compatibility

    local is_rooted=0
    if check_root; then
        is_rooted=1
        echo "Root detected: Activating kernel Netfilter (iptables) cellular drop rules."
    fi

    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            echo "Restricting: $pkg"
            local applied=0
            # 1. Suppress push notification display and associated media payload downloads
            if appops_set "$pkg" POST_NOTIFICATION ignore; then applied=$((applied + 1)); fi
            # 2. Block arbitrary background broadcast wakeups and services
            if appops_set "$pkg" RUN_ANY_IN_BACKGROUND ignore; then applied=$((applied + 1)); fi
            if appops_set "$pkg" RUN_IN_BACKGROUND ignore; then applied=$((applied + 1)); fi
            # 3. Demote to restricted standby bucket
            adb shell cmd usagestats set-app-standby-bucket "$pkg" restricted 2>/dev/null || true
            
            local uid
            uid="$(get_package_uid "$pkg")"
            if [[ -n "$uid" ]]; then
                # 4. Blacklist UID from metered background sockets in NetworkPolicyManager
                adb shell cmd netpolicy add restrict-background-blacklist "$uid" 2>/dev/null || true
                if [[ $applied -eq 3 ]]; then
                    echo "  -> AppOps restricted, standby bucket restricted, UID $uid blacklisted."
                elif [[ $applied -gt 0 ]]; then
                    echo "  -> AppOps partially applied ($applied/3), standby bucket restricted, UID $uid blacklisted."
                else
                    echo "  -> AppOps unavailable, standby bucket restricted, UID $uid blacklisted."
                fi
                
                # 5. If root is available, apply hardware/kernel-level drop on cellular interfaces
                if [[ $is_rooted -eq 1 ]]; then
                    apply_iptables_uid_drop "$uid"
                    echo "  -> Kernel iptables cellular drop rule applied for UID $uid."
                fi
            fi
        else
            echo "Skipping uninstalled package: $pkg"
        fi
    done

    if [[ $is_rooted -eq 1 ]]; then
        install_boot_hook "/data/adb/service.d/devsubstrate-shopping-restrictions.sh" 1 "${TARGET_PACKAGES[@]}" || true
    fi

    echo ""
    if [[ $APP_OPS_AVAILABLE -eq 0 ]]; then
        echo "Partial: standby buckets and UID blacklist applied. AppOps notification and background controls were refused by this build."
        echo "Fix the permission monitor and rerun with 'pause' to apply the rest."
        return 1
    fi

    echo "Finished. WhatsApp, Instagram, Telegram, and Hotspot routing remain unhindered."
}

resume_traffic() {
    echo "Restoring background activity and notifications..."

    local is_rooted=0
    if check_root; then
        is_rooted=1
        echo "Root detected: Flushing kernel Netfilter (iptables) cellular drop rules."
    fi

    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            echo "Restoring: $pkg"
            local applied=0
            if appops_set "$pkg" POST_NOTIFICATION allow; then applied=$((applied + 1)); fi
            if appops_set "$pkg" RUN_ANY_IN_BACKGROUND allow; then applied=$((applied + 1)); fi
            if appops_set "$pkg" RUN_IN_BACKGROUND allow; then applied=$((applied + 1)); fi
            adb shell cmd usagestats set-app-standby-bucket "$pkg" active 2>/dev/null || true
            
            local uid
            uid="$(get_package_uid "$pkg")"
            if [[ -n "$uid" ]]; then
                adb shell cmd netpolicy remove restrict-background-blacklist "$uid" 2>/dev/null || true
                if [[ $is_rooted -eq 1 ]]; then
                    remove_iptables_uid_drop "$uid"
                fi
                if [[ $applied -eq 3 ]]; then
                    echo "  -> AppOps restored, standby bucket active, UID $uid removed from blacklist."
                else
                    echo "  -> AppOps partially restored ($applied/3), standby bucket active, UID $uid removed from blacklist."
                fi
            fi
        else
            echo "Skipping uninstalled package: $pkg"
        fi
    done

    if [[ $is_rooted -eq 1 ]]; then
        remove_boot_hook "/data/adb/service.d/devsubstrate-shopping-restrictions.sh"
    fi

    echo ""
    if [[ $APP_OPS_AVAILABLE -eq 0 ]]; then
        echo "Partial: standby buckets and UID blacklist restored. AppOps modes were not changed."
        return 1
    fi
    echo "Finished. Default settings restored."
}

show_status() {
    echo "=========================================================="
    echo "Current Restriction Status for Target Packages"
    echo "=========================================================="
    check_oem_and_root_compatibility

    if ! appops_available; then
        report_appops_blocked
    fi

    local is_rooted=0
    if check_root; then
        is_rooted=1
    fi

    echo ""
    echo "Inspecting installed packages:"
    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            local post_notif
            local run_bg
            local bucket
            local uid
            uid="$(get_package_uid "$pkg")"
            post_notif="$(appops_get "$pkg" POST_NOTIFICATION)"
            run_bg="$(appops_get "$pkg" RUN_ANY_IN_BACKGROUND)"
            bucket="$(adb shell cmd usagestats get-app-standby-bucket "$pkg" 2>/dev/null | tr -d '\r\n' || echo "unknown")"
            
            echo "Package: $pkg (UID: ${uid:-unknown})"
            echo "  POST_NOTIFICATION:     $post_notif"
            echo "  RUN_ANY_IN_BACKGROUND: $run_bg"
            echo "  Standby Bucket:        $bucket"
            if [[ $is_rooted -eq 1 && -n "$uid" ]]; then
                local ipt_active="No"
                if run_as_root "iptables -S OUTPUT 2>/dev/null" | grep -q "uid-owner $uid -j DROP"; then
                    ipt_active="Yes (Cellular interface DROP active)"
                fi
                echo "  iptables Kernel Rule:  $ipt_active"
            fi
        fi
    done
}

automate_ui() {
    echo "=========================================================="
    echo "Automating Background Data Toggle via UI / Accessibility"
    echo "=========================================================="
    echo "This mode opens App Info for each target app to verify or"
    echo "toggle the Background Data switch in Settings."
    echo ""

    # Check if custom accessibility service is enabled
    local enabled_services
    enabled_services=$(adb shell settings get secure enabled_accessibility_services 2>/dev/null || echo "")
    if echo "$enabled_services" | grep -q "dev.substrate.dataautomation"; then
        echo "[+] Custom Accessibility Service detected and active."
        echo "    The service will automatically detect the settings window and click toggles."
    else
        echo "[i] Custom Accessibility Service not active."
        echo "    Running ADB UIAutomator traversal to inspect and toggle screens."
        echo "    For hands-free operation, you can install the Substrate Accessibility Service"
        echo "    from 'android/accessibility-service'."
    fi
    echo ""

    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            echo "Opening settings for: $pkg"
            # Launch App Info settings directly
            adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:$pkg" >/dev/null 2>&1
            sleep 1.5

            # Attempt to dump current window hierarchy
            adb shell uiautomator dump /data/local/tmp/app_info.xml >/dev/null 2>&1 || true
            local dump_content
            dump_content=$(adb shell cat /data/local/tmp/app_info.xml 2>/dev/null || echo "")

            # Look for Mobile data & Wi-Fi entry bounds
            if echo "$dump_content" | grep -qi "Mobile data"; then
                local bounds
                bounds=$(echo "$dump_content" | grep -i -B 2 -A 2 "Mobile data" | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | head -n 1 || true)
                if [[ -n "$bounds" ]]; then
                    # Extract coordinates [x1,y1][x2,y2]
                    local x1 y1 x2 y2
                    x1=$(echo "$bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\1/')
                    y1=$(echo "$bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\2/')
                    x2=$(echo "$bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\3/')
                    y2=$(echo "$bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\4/')
                    local click_x=$(( (x1 + x2) / 2 ))
                    local click_y=$(( (y1 + y2) / 2 ))
                    echo "  -> Navigating into Mobile data & Wi-Fi ($click_x, $click_y)..."
                    adb shell input tap "$click_x" "$click_y"
                    sleep 1.2

                    # Dump sub-window to find Background data toggle
                    adb shell uiautomator dump /data/local/tmp/data_sub.xml >/dev/null 2>&1 || true
                    local sub_dump
                    sub_dump=$(adb shell cat /data/local/tmp/data_sub.xml 2>/dev/null || echo "")

                    if echo "$sub_dump" | grep -qi "Background data"; then
                        # Check if switch is currently checked
                        local switch_bounds
                        switch_bounds=$(echo "$sub_dump" | grep -i -B 3 -A 3 "Background data" | grep 'class="android.widget.Switch"' | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | head -n 1 || true)
                        local is_checked
                        is_checked=$(echo "$sub_dump" | grep -i -B 3 -A 3 "Background data" | grep 'class="android.widget.Switch"' | grep -o 'checked="[^"]*"' | head -n 1 || true)

                        if [[ "$is_checked" == 'checked="true"' && -n "$switch_bounds" ]]; then
                            local sx1 sy1 sx2 sy2
                            sx1=$(echo "$switch_bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\1/')
                            sy1=$(echo "$switch_bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\2/')
                            sx2=$(echo "$switch_bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\3/')
                            sy2=$(echo "$switch_bounds" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\4/')
                            local switch_x=$(( (sx1 + sx2) / 2 ))
                            local switch_y=$(( (sy1 + sy2) / 2 ))
                            echo "  -> Background data switch is active. Toggling OFF ($switch_x, $switch_y)..."
                            adb shell input tap "$switch_x" "$switch_y"
                            sleep 0.5
                        else
                            echo "  -> Background data is already disabled or switch was not in ON state."
                        fi
                    fi
                    # Press Back to exit sub-menu
                    adb shell input keyevent 4
                    sleep 0.5
                fi
            fi
            # Press Back to exit App Info
            adb shell input keyevent 4
            sleep 0.5
        fi
    done
    # Return to home
    adb shell input keyevent 3
    echo ""
    echo "[+] UI / Accessibility automation traversal complete."
}

main() {
    check_adb
    local action="${1:-}"

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
        automate-ui)
            automate_ui
            ;;
        *)
            echo "Usage: $0 {pause|resume|status|check|automate-ui}"
            exit 1
            ;;
    esac
}

main "$@"
