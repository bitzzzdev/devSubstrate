#!/usr/bin/env fish
#
# hotspot-background-traffic-control.fish: Restricts or restores background traffic
# for non-essential third-party apps on Android to protect mobile hotspot bandwidth.
#
# Supports smart root and OEM unlocking diagnostics, kernel-level iptables filtering,
# NetPolicy cellular blacklisting, standby bucketing, and modem idle power optimization.
#
# Preserves essential messengers (WhatsApp, Telegram, Signal) and hotspot routing.
#
# Usage:
#   ./hotspot-background-traffic-control.fish apply   # Restricts background data on third-party apps
#   ./hotspot-background-traffic-control.fish revert  # Restores default background execution states
#   ./hotspot-background-traffic-control.fish status  # Lists currently restricted packages
#   ./hotspot-background-traffic-control.fish check   # Checks root and OEM unlocking compatibility
#

set -l WHITELIST \
    com.whatsapp \
    org.telegram.messenger \
    org.thoughtcrime.securesms \
    com.google.android.gms

set -l CELLULAR_INTERFACES rmnet+ ccmni+ pdp+ wwan+

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

function check_root
    if adb shell "id" 2>/dev/null | grep -q "uid=0(root)"
        return 0
    end
    if adb shell "command -v su >/dev/null 2>&1 && su -c id 2>/dev/null" | grep -q "uid=0"
        return 0
    end
    return 1
end

function run_as_root -a cmd
    if adb shell "id" 2>/dev/null | grep -q "uid=0(root)"
        adb shell "$cmd"
    else
        adb shell "su -c \"$cmd\""
    end
end

function check_oem_and_root_compatibility
    echo "=========================================================="
    echo "Device Compatibility: Root and Bootloader Lock Diagnostics"
    echo "=========================================================="

    set -l has_root 0
    if check_root
        set has_root 1
    end

    set -l oem_unlock_allowed (adb shell getprop sys.oem_unlock_allowed 2>/dev/null | string trim)
    set -l bootloader_locked (adb shell getprop ro.boot.flash.locked 2>/dev/null | string trim)
    set -l verified_boot (adb shell getprop ro.boot.verifiedbootstate 2>/dev/null | string trim)
    set -l oem_unlock_supported (adb shell getprop ro.oem_unlock_supported 2>/dev/null | string trim)

    echo "Diagnostic Properties:"
    if test $has_root -eq 1
        echo "  - Root Privilege:               Available (uid 0)"
    else
        echo "  - Root Privilege:               Not present"
    end
    echo "  - OEM Unlocking (sys):          $oem_unlock_allowed (1=allowed, 0=blocked)"
    echo "  - Bootloader Lock (flash):      $bootloader_locked (1=locked, 0=unlocked)"
    echo "  - Verified Boot State:          $verified_boot"
    echo "  - OEM Unlock Supported:         $oem_unlock_supported"
    echo ""

    if test $has_root -eq 1
        echo "[+] ROOT DETECTED: Full kernel-level iptables socket filtering enabled."
        echo "    Cellular packets will be filtered directly via kernel Netfilter hooks."
        return 0
    end

    if test "$bootloader_locked" = "0"
        echo "[i] Bootloader is UNLOCKED (ro.boot.flash.locked=0)."
        echo "    Device has an unlocked bootloader. For maximum compatibility and kernel-level"
        echo "    iptables packet filtering, install Magisk or KernelSU to grant root privileges."
        echo "    Continuing in standard ADB mode (AppOps + NetPolicy + Standby Buckets)..."
        return 0
    end

    if test "$oem_unlock_allowed" != "1"
        echo "[!] COMPATIBILITY WARNING: OEM Unlocking is DISABLED on this device."
        echo "    Current status: sys.oem_unlock_allowed=$oem_unlock_allowed"
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
    end
    echo "=========================================================="
end

function is_whitelisted -a pkg
    for w in $WHITELIST
        if test "$pkg" = "$w"
            return 0
        end
    end
    return 1
end

function optimize_cellular_idle_settings
    adb shell settings put global mobile_data_always_on 0 >/dev/null 2>&1
    adb shell settings put global tether_dun_required 0 >/dev/null 2>&1
    adb shell settings put global tether_offload_disabled 0 >/dev/null 2>&1
end

function apply_iptables_uid_drop -a uid
    for iface in $CELLULAR_INTERFACES
        run_as_root "iptables -C OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || iptables -I OUTPUT -o $iface -m owner --uid-owner $uid -j DROP" >/dev/null 2>&1
        run_as_root "ip6tables -C OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || ip6tables -I OUTPUT -o $iface -m owner --uid-owner $uid -j DROP" >/dev/null 2>&1
    end
end

function remove_iptables_uid_drop -a uid
    for iface in $CELLULAR_INTERFACES
        run_as_root "iptables -D OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || true" >/dev/null 2>&1
        run_as_root "ip6tables -D OUTPUT -o $iface -m owner --uid-owner $uid -j DROP 2>/dev/null || true" >/dev/null 2>&1
    end
end

# Magisk and KernelSU run every /data/adb/service.d/*.sh as root at the late_start
# service phase. The hook re-applies AppOps, standby bucket, NetPolicy blacklist and
# iptables rules after every reboot so the restrictions survive restarts. The hook is
# deleted by the revert action, or by a factory reset, which wipes /data.
function install_boot_hook -a hook_path
    set -l packages $argv[2..-1]
    if not run_as_root "test -d /data/adb/service.d" >/dev/null 2>&1
        echo "[i] /data/adb/service.d is missing. Install Magisk or KernelSU to persist restrictions across reboots."
        return 1
    end
    set -l hook_tmp (mktemp /tmp/devsubstrate-boot-hook.XXXXXX.sh)
    set -l remote "/data/local/tmp/"(basename $hook_path)
    begin
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
    end > $hook_tmp
    if not adb push $hook_tmp $remote >/dev/null 2>&1
        rm -f $hook_tmp
        echo "[!] Could not push boot hook to device." >&2
        return 1
    end
    if run_as_root "cp $remote $hook_path && chmod 755 $hook_path && rm -f $remote" >/dev/null 2>&1
        echo "[+] Boot hook installed at $hook_path. It survives reboots until the revert action runs."
    else
        rm -f $hook_tmp $remote
        echo "[!] Could not install boot hook at $hook_path." >&2
        return 1
    end
    rm -f $hook_tmp
end

function remove_boot_hook -a hook_path
    set -l remote "/data/local/tmp/"(basename $hook_path)
    run_as_root "rm -f $hook_path $remote" >/dev/null 2>&1
    echo "[i] Boot hook removed if present: $hook_path"
end

function status_restrictions
    echo "=========================================================="
    echo "Current Network Policy and Background Status"
    echo "=========================================================="
    check_oem_and_root_compatibility
    echo ""
    echo "=== Data Saver State ==="
    adb shell cmd netpolicy get restrict-background 2>/dev/null; or echo "Unavailable."
    echo ""
    echo "=== Network Policy Blacklist ==="
    adb shell cmd netpolicy list restrict-background-blacklist 2>/dev/null; or echo "Empty or unavailable."
end

function apply_restrictions
    echo "Ensuring global Data Saver remains off so hotspot functions..."
    adb shell cmd netpolicy set restrict-background false
    check_oem_and_root_compatibility
    optimize_cellular_idle_settings

    set -l is_rooted 0
    if check_root
        set is_rooted 1
        echo "Root detected: Kernel Netfilter rules will be applied to drop cellular packets."
    end

    set -l restricted_pkgs
    echo "Optimizing third-party application background limits..."
    set -l packages (adb shell pm list packages -3 2>/dev/null | string replace "package:" "" | string trim)

    for pkg in $packages
        test -z "$pkg"; and continue

        if is_whitelisted $pkg
            echo "Skipping whitelisted essential messenger: $pkg"
            continue
        end

        set -l uid (adb shell dumpsys package $pkg 2>/dev/null | string match -rg "userId=([0-9]+)" | head -n 1)

        if test -n "$uid"
            adb shell cmd netpolicy add restrict-background-blacklist $uid >/dev/null 2>&1
            adb shell cmd appops set $pkg RUN_IN_BACKGROUND ignore >/dev/null 2>&1
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1
            adb shell cmd usagestats set-app-standby-bucket $pkg restricted >/dev/null 2>&1
            if test $is_rooted -eq 1
                apply_iptables_uid_drop $uid
                set -a restricted_pkgs $pkg
            end
            echo "Restricted: $pkg (UID: $uid)"
        end
    end

    if test $is_rooted -eq 1
        if test (count $restricted_pkgs) -gt 0
            install_boot_hook "/data/adb/service.d/devsubstrate-hotspot-restrictions.sh" $restricted_pkgs
        else
            echo "[i] No third-party packages were restricted; skipping boot hook install."
        end
    end

    echo ""
    echo "Done. Background data restricted while hotspot remains active."
end

function revert_restrictions
    echo "Restoring third-party packages to Android defaults..."
    adb shell cmd netpolicy set restrict-background false

    set -l is_rooted 0
    if check_root
        set is_rooted 1
        echo "Root detected: Flushing kernel Netfilter rules."
    end

    set -l packages (adb shell pm list packages -3 2>/dev/null | string replace "package:" "" | string trim)

    for pkg in $packages
        test -z "$pkg"; and continue

        set -l uid (adb shell dumpsys package $pkg 2>/dev/null | string match -rg "userId=([0-9]+)" | head -n 1)

        if test -n "$uid"
            adb shell cmd netpolicy remove restrict-background-blacklist $uid >/dev/null 2>&1
            adb shell cmd appops set $pkg RUN_IN_BACKGROUND default >/dev/null 2>&1
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND default >/dev/null 2>&1
            adb shell cmd usagestats set-app-standby-bucket $pkg active >/dev/null 2>&1
            if test $is_rooted -eq 1
                remove_iptables_uid_drop $uid
            end
            echo "Restored: $pkg (UID: $uid)"
        end
    end

    if test $is_rooted -eq 1
        remove_boot_hook "/data/adb/service.d/devsubstrate-hotspot-restrictions.sh"
    end

    echo ""
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
    case "check"
        check_oem_and_root_compatibility
    case '*'
        echo "Usage: "(status filename)" {apply|revert|status|check}"
        exit 1
end
