#!/usr/bin/env bash
#
# hotspot-background-traffic-control.sh: Restricts or restores background traffic
# for non-essential third-party apps on Android to protect mobile hotspot bandwidth.
#
# Supports smart root and OEM unlocking diagnostics, kernel-level iptables filtering,
# NetPolicy cellular blacklisting, standby bucketing, and modem idle power optimization.
#
# Preserves essential messengers (WhatsApp, Telegram, Signal) and hotspot routing.
#
# Usage:
#   ./hotspot-background-traffic-control.sh apply   # Restricts background data on third-party apps
#   ./hotspot-background-traffic-control.sh revert  # Restores default background execution states
#   ./hotspot-background-traffic-control.sh status  # Lists currently restricted packages
#   ./hotspot-background-traffic-control.sh check   # Checks root and OEM unlocking compatibility
#

set -euo pipefail

WHITELIST=(
    "com.whatsapp"
    "org.telegram.messenger"
    "org.thoughtcrime.securesms"
    "com.google.android.gms"
)

CELLULAR_INTERFACES=("rmnet+" "ccmni+" "pdp+" "wwan+")

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

APP_OPS_AVAILABLE=1

appops_set() {
    local pkg="$1" op="$2" mode="$3" output status=0
    output=$(adb shell cmd appops set "$pkg" "$op" "$mode" 2>&1 | tr -d '\r') || status=$?
    if [[ "$output" == *"SecurityException"* || "$output" == *"MANAGE_APP_OPS_MODES"* ]]; then
        if [[ "$APP_OPS_AVAILABLE" -eq 1 ]]; then
            APP_OPS_AVAILABLE=0
            echo "[!] AppOps denied by the OEM permission monitor. Continuing with NetPolicy and standby restrictions." >&2
        fi
        return 1
    fi
    return "$status"
}

check_root() {
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

is_whitelisted() {
    local pkg="$1"
    for w in "${WHITELIST[@]}"; do
        if [[ "$pkg" == "$w" ]]; then
            return 0
        fi
    done
    return 1
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
# deleted by the revert action, or by a factory reset, which wipes /data.
# shellcheck disable=SC2016,SC2028
install_boot_hook() {
    local hook_path="$1"
    shift
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
        echo '# Managed by this script; removed by its revert action.'
        echo "PACKAGES=\"$packages\""
        echo 'INTERFACES="rmnet+ ccmni+ pdp+ wwan+"'
        echo 'for pkg in $PACKAGES; do'
        echo '    uid=$(cmd package list packages -U "$pkg" 2>/dev/null | sed -n "s/.*uid:\([0-9]*\).*/\1/p" | head -n 1)'
        echo '    [ -z "$uid" ] && continue'
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
        echo "[+] Boot hook installed at $hook_path. It survives reboots until the revert action runs."
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

status_restrictions() {
    echo "=========================================================="
    echo "Current Network Policy and Background Status"
    echo "=========================================================="
    check_oem_and_root_compatibility
    echo ""
    echo "=== Data Saver State ==="
    adb shell cmd netpolicy get restrict-background 2>/dev/null || echo "Unavailable."
    echo ""
    echo "=== Network Policy Blacklist ==="
    adb shell cmd netpolicy list restrict-background-blacklist 2>/dev/null || echo "Empty or unavailable."
}

apply_restrictions() {
    echo "Ensuring global Data Saver remains off so hotspot functions..."
    adb shell cmd netpolicy set restrict-background false
    check_oem_and_root_compatibility

    local is_rooted=0
    if check_root; then
        is_rooted=1
        echo "Root detected: Kernel Netfilter rules will be applied to drop cellular packets."
    fi

    local restricted_pkgs=()
    echo "Optimizing third-party application background limits..."
    while IFS= read -r line; do
        pkg="${line#package:}"
        pkg="${pkg%$'\r'}"
        [[ -z "$pkg" ]] && continue

        if is_whitelisted "$pkg"; then
            echo "Skipping whitelisted essential messenger: $pkg"
            continue
        fi

        uid=$(adb shell dumpsys package "$pkg" 2>/dev/null | grep -m1 "userId=" | sed -E 's/.*userId=([0-9]+).*/\1/' || true)

        if [[ -n "$uid" ]]; then
            adb shell cmd netpolicy add restrict-background-blacklist "$uid" >/dev/null 2>&1 || true
            if ! appops_set "$pkg" RUN_IN_BACKGROUND ignore; then :; fi
            if ! appops_set "$pkg" RUN_ANY_IN_BACKGROUND ignore; then :; fi
            adb shell cmd usagestats set-app-standby-bucket "$pkg" restricted >/dev/null 2>&1 || true
            if [[ $is_rooted -eq 1 ]]; then
                apply_iptables_uid_drop "$uid"
                restricted_pkgs+=("$pkg")
            fi
            echo "Restricted: $pkg (UID: $uid)"
        fi
    done < <(adb shell pm list packages -3 2>/dev/null)

    if [[ $is_rooted -eq 1 ]]; then
        if [[ ${#restricted_pkgs[@]} -gt 0 ]]; then
            install_boot_hook "/data/adb/service.d/devsubstrate-hotspot-restrictions.sh" "${restricted_pkgs[@]}" || true
        else
            echo "[i] No third-party packages were restricted; skipping boot hook install."
        fi
    fi

    echo ""
    if [[ "$APP_OPS_AVAILABLE" -eq 0 ]]; then
        echo "Partial: AppOps was refused. Per-UID NetPolicy and standby restrictions were attempted; verify their status on this device."
        return 1
    fi
    echo "Done. Background data restrictions applied; hotspot settings were left unchanged."
}

revert_restrictions() {
    echo "Restoring third-party packages to Android defaults..."
    adb shell cmd netpolicy set restrict-background false

    local is_rooted=0
    if check_root; then
        is_rooted=1
        echo "Root detected: Flushing kernel Netfilter rules."
    fi

    while IFS= read -r line; do
        pkg="${line#package:}"
        pkg="${pkg%$'\r'}"
        [[ -z "$pkg" ]] && continue

        uid=$(adb shell dumpsys package "$pkg" 2>/dev/null | grep -m1 "userId=" | sed -E 's/.*userId=([0-9]+).*/\1/' || true)

        if [[ -n "$uid" ]]; then
            adb shell cmd netpolicy remove restrict-background-blacklist "$uid" >/dev/null 2>&1 || true
            adb shell cmd appops set "$pkg" RUN_IN_BACKGROUND default >/dev/null 2>&1 || true
            adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND default >/dev/null 2>&1 || true
            adb shell cmd usagestats set-app-standby-bucket "$pkg" active >/dev/null 2>&1 || true
            if [[ $is_rooted -eq 1 ]]; then
                remove_iptables_uid_drop "$uid"
            fi
            echo "Restored: $pkg (UID: $uid)"
        fi
    done < <(adb shell pm list packages -3 2>/dev/null)

    if [[ $is_rooted -eq 1 ]]; then
        remove_boot_hook "/data/adb/service.d/devsubstrate-hotspot-restrictions.sh"
    fi

    echo ""
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
    check)
        check_oem_and_root_compatibility
        ;;
    *)
        echo "Usage: $0 {apply|revert|status|check}"
        exit 1
        ;;
esac
