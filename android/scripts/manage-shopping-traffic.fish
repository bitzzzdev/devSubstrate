#!/usr/bin/env fish
#
# manage-shopping-traffic.fish: Fish shell script to selectively pause or resume
# background data and notifications for shopping, quick commerce, and delivery apps via ADB.
#
# Supports smart root and OEM unlocking detection, kernel-level iptables filtering,
# AppOps notification suppression, NetPolicy cellular blacklisting, standby bucketing,
# and UI/Accessibility automation to toggle background data across OEM skins.
#
# Preserves WhatsApp, Instagram, Telegram, Google Play Services, and Wi-Fi Hotspot.
#
# Usage:
#   ./manage-shopping-traffic.fish pause         # Restricts shopping apps
#   ./manage-shopping-traffic.fish resume        # Restores shopping apps
#   ./manage-shopping-traffic.fish status        # Displays current restriction status
#   ./manage-shopping-traffic.fish check         # Checks root and OEM unlocking compatibility
#   ./manage-shopping-traffic.fish automate-ui   # UI automation to toggle background data
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

function get_package_uid -a pkg
    set -l raw (adb shell cmd package list packages -U $pkg 2>/dev/null)
    string match -rg 'uid:([0-9]+)' $raw | tail -n 1
end

function is_package_installed -a pkg
    # adb appends CR to every line; strip it or the exact match never succeeds.
    adb shell pm list packages $pkg 2>/dev/null | string replace -a -r '\r' '' | string match -q "package:$pkg"
end

function set_tethering_offload
    if adb shell settings put global tether_offload_disabled 0 >/dev/null 2>&1
        set -l current (adb shell settings get global tether_offload_disabled 2>/dev/null | string trim)
        if test "$current" = "0"
            echo "Confirmed tethering hardware offload enabled (0)."
            return 0
        end
    end
    echo "Warning: Android denied the tethering offload setting. Continuing with app restrictions." >&2
end

function optimize_cellular_idle_settings
    if adb shell settings put global mobile_data_always_on 0 >/dev/null 2>&1
        echo "Confirmed mobile data always active disabled (0). Prevents background cellular leak."
    end
    adb shell settings put global tether_dun_required 0 >/dev/null 2>&1
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
# deleted by the resume/revert action, or by a factory reset, which wipes /data.
function install_boot_hook -a hook_path with_post_notification
    set -l packages $argv[3..-1]
    if not run_as_root "test -d /data/adb/service.d" >/dev/null 2>&1
        echo "[i] /data/adb/service.d is missing. Install Magisk or KernelSU to persist restrictions across reboots."
        return 1
    end
    set -l hook_tmp (mktemp /tmp/devsubstrate-boot-hook.XXXXXX.sh)
    set -l remote "/data/local/tmp/"(basename $hook_path)
    begin
        echo '#!/system/bin/sh'
        echo '# devSubstrate boot hook. Re-applies background restrictions after reboot.'
        echo '# Managed by this script; removed by its resume/revert action.'
        echo "PACKAGES=\"$packages\""
        echo 'INTERFACES="rmnet+ ccmni+ pdp+ wwan+"'
        echo 'for pkg in $PACKAGES; do'
        echo '    uid=$(cmd package list packages -U "$pkg" 2>/dev/null | sed -n "s/.*uid:\([0-9]*\).*/\1/p" | head -n 1)'
        echo '    [ -z "$uid" ] && continue'
        if test "$with_post_notification" = "1"
            echo '    cmd appops set "$pkg" POST_NOTIFICATION ignore 2>/dev/null'
        end
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
        echo "[+] Boot hook installed at $hook_path. It survives reboots until the resume/revert action runs."
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

function pause_traffic
    echo "Applying selective background and notification restrictions..."
    check_oem_and_root_compatibility
    set_tethering_offload
    optimize_cellular_idle_settings

    set -l is_rooted 0
    if check_root
        set is_rooted 1
        echo "Root detected: Activating kernel Netfilter (iptables) cellular drop rules."
    end

    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            echo "Restricting: $pkg"
            adb shell cmd appops set $pkg POST_NOTIFICATION ignore
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore
            adb shell cmd appops set $pkg RUN_IN_BACKGROUND ignore
            adb shell cmd usagestats set-app-standby-bucket $pkg restricted >/dev/null 2>&1

            set -l uid (get_package_uid $pkg)
            if test -n "$uid"
                adb shell cmd netpolicy add restrict-background-blacklist $uid 2>/dev/null
                echo "  -> AppOps restricted, standby bucket set to restricted, UID $uid blacklisted."
                if test $is_rooted -eq 1
                    apply_iptables_uid_drop $uid
                    echo "  -> Kernel iptables cellular drop rule applied for UID $uid."
                end
            end
        else
            echo "Skipping uninstalled package: $pkg"
        end
    end

    if test $is_rooted -eq 1
        install_boot_hook "/data/adb/service.d/devsubstrate-shopping-restrictions.sh" 1 $TARGET_PACKAGES; or true
    end

    echo ""
    echo "Finished. WhatsApp, Instagram, Telegram, and Hotspot routing remain unhindered."
end

function resume_traffic
    echo "Restoring background activity and notifications..."

    set -l is_rooted 0
    if check_root
        set is_rooted 1
        echo "Root detected: Flushing kernel Netfilter (iptables) cellular drop rules."
    end

    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            echo "Restoring: $pkg"
            adb shell cmd appops set $pkg POST_NOTIFICATION allow
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND allow
            adb shell cmd appops set $pkg RUN_IN_BACKGROUND allow
            adb shell cmd usagestats set-app-standby-bucket $pkg active >/dev/null 2>&1

            set -l uid (get_package_uid $pkg)
            if test -n "$uid"
                adb shell cmd netpolicy remove restrict-background-blacklist $uid 2>/dev/null
                if test $is_rooted -eq 1
                    remove_iptables_uid_drop $uid
                end
                echo "  -> AppOps restored, standby bucket set to active, UID $uid removed from blacklist."
            end
        else
            echo "Skipping uninstalled package: $pkg"
        end
    end

    if test $is_rooted -eq 1
        remove_boot_hook "/data/adb/service.d/devsubstrate-shopping-restrictions.sh"
    end

    echo ""
    echo "Finished. Default settings restored."
end

function show_status
    echo "=========================================================="
    echo "Current Restriction Status for Target Packages"
    echo "=========================================================="
    check_oem_and_root_compatibility

    set -l is_rooted 0
    if check_root
        set is_rooted 1
    end

    echo ""
    echo "Inspecting installed packages:"
    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            set -l uid (get_package_uid $pkg)
            set -l post_notif (adb shell cmd appops get $pkg POST_NOTIFICATION 2>/dev/null | head -n 1)
            set -l run_bg (adb shell cmd appops get $pkg RUN_ANY_IN_BACKGROUND 2>/dev/null | head -n 1)
            set -l bucket (adb shell cmd usagestats get-app-standby-bucket $pkg 2>/dev/null | string trim)
            echo "Package: $pkg (UID: $uid)"
            echo "  POST_NOTIFICATION:     $post_notif"
            echo "  RUN_ANY_IN_BACKGROUND: $run_bg"
            echo "  Standby Bucket:        $bucket"
            if test $is_rooted -eq 1 -a -n "$uid"
                set -l ipt_active "No"
                if run_as_root "iptables -S OUTPUT 2>/dev/null" | grep -q "uid-owner $uid -j DROP"
                    set ipt_active "Yes (Cellular interface DROP active)"
                end
                echo "  iptables Kernel Rule:  $ipt_active"
            end
        end
    end
end

function automate_ui
    echo "=========================================================="
    echo "Automating Background Data Toggle via UI / Accessibility"
    echo "=========================================================="
    echo "This mode opens App Info for each target app to verify or"
    echo "toggle the Background Data switch in Settings."
    echo ""

    set -l enabled_services (adb shell settings get secure enabled_accessibility_services 2>/dev/null)
    if string match -q "*dev.substrate.dataautomation*" "$enabled_services"
        echo "[+] Custom Accessibility Service detected and active."
        echo "    The service will automatically detect the settings window and click toggles."
    else
        echo "[i] Custom Accessibility Service not active."
        echo "    Running ADB UIAutomator traversal to inspect and toggle screens."
        echo "    For hands-free operation, you can install the Substrate Accessibility Service"
        echo "    from 'android/accessibility-service'."
    end
    echo ""

    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            echo "Opening settings for: $pkg"
            adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:$pkg" >/dev/null 2>&1
            sleep 1.5

            adb shell uiautomator dump /data/local/tmp/app_info.xml >/dev/null 2>&1
            set -l dump_content (adb shell cat /data/local/tmp/app_info.xml 2>/dev/null)

            if string match -q -i "*Mobile data*" "$dump_content"
                set -l bounds (echo "$dump_content" | grep -i -B 2 -A 2 "Mobile data" | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | head -n 1)
                if test -n "$bounds"
                    set -l coords (string match -rg 'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"' $bounds)
                    # -g prints only the capture groups: x1 y1 x2 y2 in elements 1-4.
                    set -l click_x (math "($coords[1] + $coords[3]) / 2")
                    set -l click_y (math "($coords[2] + $coords[4]) / 2")
                    echo "  -> Navigating into Mobile data & Wi-Fi ($click_x, $click_y)..."
                    adb shell input tap $click_x $click_y
                    sleep 1.2

                    adb shell uiautomator dump /data/local/tmp/data_sub.xml >/dev/null 2>&1
                    set -l sub_dump (adb shell cat /data/local/tmp/data_sub.xml 2>/dev/null)

                    if string match -q -i "*Background data*" "$sub_dump"
                        set -l switch_bounds (echo "$sub_dump" | grep -i -B 3 -A 3 "Background data" | grep 'class="android.widget.Switch"' | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | head -n 1)
                        set -l is_checked (echo "$sub_dump" | grep -i -B 3 -A 3 "Background data" | grep 'class="android.widget.Switch"' | grep -o 'checked="[^"]*"' | head -n 1)

                        if test "$is_checked" = 'checked="true"' -a -n "$switch_bounds"
                            set -l scoords (string match -rg 'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"' $switch_bounds)
                            set -l switch_x (math "($scoords[1] + $scoords[3]) / 2")
                            set -l switch_y (math "($scoords[2] + $scoords[4]) / 2")
                            echo "  -> Background data switch is active. Toggling OFF ($switch_x, $switch_y)..."
                            adb shell input tap $switch_x $switch_y
                            sleep 0.5
                        else
                            echo "  -> Background data is already disabled or switch was not in ON state."
                        end
                    end
                    adb shell input keyevent 4
                    sleep 0.5
                end
            end
            adb shell input keyevent 4
            sleep 0.5
        end
    end
    adb shell input keyevent 3
    echo ""
    echo "[+] UI / Accessibility automation traversal complete."
end

if not check_adb
    exit 1
end

set -l action $argv[1]

switch "$action"
    case "pause"
        pause_traffic
    case "resume"
        resume_traffic
    case "status"
        show_status
    case "check"
        check_oem_and_root_compatibility
    case "automate-ui"
        automate_ui
    case '*'
        echo "Usage: "(status filename)" {pause|resume|status|check|automate-ui}"
        exit 1
end
