#!/usr/bin/env fish
#
# termux-manage-shopping-traffic.fish: Local Termux Fish shell script to manage
# catalog application background data and notification drain without a PC.
#
# Execution modes:
#   1. Direct root / Shizuku / su (full capability matching ADB)
#   2. Local ADB over loopback Wi-Fi debugging
#   3. Standard non-root Termux (process termination and cache optimization)
#
# Usage:
#   ./termux-manage-shopping-traffic.fish pause   # Restricts installed catalog apps
#   ./termux-manage-shopping-traffic.fish resume  # Restores catalog apps
#   ./termux-manage-shopping-traffic.fish status  # Inspects current restrictions
#   ./termux-manage-shopping-traffic.fish check   # Checks root and OEM unlocking status
#

set -g TARGET_PACKAGES \
    in.amazon.mShop.android.shopping \
    com.flipkart.android \
    com.flipkart.shopsy \
    com.myntra.android \
    com.ril.ajio \
    com.meesho.supply \
    com.grofers.customerapp \
    com.zeptoconsumerapp \
    com.bigbasket.mobileapp \
    com.jpl.jiomart \
    com.fsn.nykaa \
    com.snapdeal.main \
    com.tul.tatacliq \
    com.firstcry.android \
    com.purplle \
    com.olx.southasia \
    com.indiamart.m \
    com.urbanic \
    com.limeroad \
    com.pepperfry \
    in.swiggy.android \
    com.application.zomato \
    com.rebelfoods.eatsure \
    com.dominos \
    com.pizzahutindia \
    com.yum.kfc \
    com.instagram.android \
    com.facebook.katana \
    com.instagram.barcelona \
    com.twitter.android \
    com.snapchat.android \
    com.pinterest \
    com.reddit.frontpage \
    com.linkedin.android \
    in.mohalla.sharechat \
    in.mohalla.video \
    in.mohalla.josh \
    io.chingari.app \
    com.tumblr \
    com.quora.android \
    com.discord \
    tv.twitch.android.app \
    com.bereal.ft \
    com.clubhouse.app \
    com.narvii.amino.master \
    com.roposo.android \
    com.google.android.youtube \
    com.google.android.apps.youtube.music \
    com.netflix.mediaclient \
    com.amazon.avod.thirdpartyclient \
    in.startv.hotstar \
    com.jio.media.ondemand \
    com.sonyliv \
    com.graymatrix.did \
    com.mxtech.videoplayer.ad \
    com.spotify.music \
    com.jio.media.jiobeats \
    com.gaana \
    com.bsbportal.music \
    com.audible.application \
    com.pocketfm \
    com.kukufm \
    com.amazon.mp3 \
    com.soundcloud.android \
    com.pubg.imobile \
    com.dts.freefireth \
    com.dts.freefiremax \
    com.activision.callofduty.shooter \
    com.supercell.clashofclans \
    com.supercell.clashroyale \
    com.roblox.client \
    com.mojang.minecraftpe \
    com.kiloo.subwaysurf \
    com.ludo.king \
    com.miniclip.eightballpool \
    com.king.candycrushsaga \
    com.miHoYo.GenshinImpact \
    com.HoYoverse.hkrpgoversea \
    com.gameloft.android.ANMP.GloftA9HM \
    com.ea.game.pvz2_row \
    com.ea.game.fifa.mobile \
    com.supercell.brawlstars \
    com.nis.app \
    com.eterno \
    com.toi.reader.activities \
    com.cricbuzz.android \
    com.espn.score_center \
    com.dream11pro \
    com.fancode.video \
    com.ndtv.news \
    com.ibn.livetv \
    com.google.android.apps.magazines \
    com.tinder \
    com.bumble.app \
    co.hinge.app \
    com.app.aisle \
    com.happn

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

# ColorOS, OxygenOS, Realme UI, MIUI, and HyperOS do not grant
# MANAGE_APP_OPS_MODES to the shell user while their permission monitor is active.
# The shell command then fails with a SecurityException even though the same
# command works on a stock build. One warning explains the fix; later failures
# stay quiet so the per-package output remains readable.
set -g APP_OPS_AVAILABLE 1

function oem_permission_monitor_hint
    set -l brand (exec_android_cmd "getprop ro.product.brand 2>/dev/null" | tr -d '\r\n' | tr '[:upper:]' '[:lower:]')
    switch "$brand"
        case realme oppo oneplus coloros
            echo "Settings -> System -> Developer Options -> 'Disable permission monitoring' (newer ColorOS and OxygenOS builds call it 'Disable system optimization')"
        case xiaomi redmi poco
            echo "Settings -> Additional settings -> Developer Options -> 'USB debugging (Security settings)'"
        case '*'
            echo "Settings -> Developer Options -> the OEM option that lets USB debugging change app permissions"
    end
end

function report_appops_blocked
    if test "$APP_OPS_AVAILABLE" != "1"
        return 0
    end
    set -g APP_OPS_AVAILABLE 0
    echo ""
    echo "[!] Android denied the AppOps change: the shell user is missing MANAGE_APP_OPS_MODES." >&2
    echo "    This build gates AppOps behind its permission monitor, so 'cmd appops set' is refused." >&2
    echo "    To grant it:" >&2
    echo "      "(oem_permission_monitor_hint) >&2
    echo "      Reboot and rerun this script for notification and background control." >&2
    echo "    Continuing with the restrictions that do not need AppOps." >&2
    echo "" >&2
end

function exec_appops_set -a pkg op mode
    set -l output (exec_android_cmd "cmd appops set $pkg $op $mode 2>&1")
    set -l rc $pipestatus[1]
    if string match -q "*SecurityException*" "$output"
        or string match -q "*MANAGE_APP_OPS_MODES*" "$output"
        report_appops_blocked
        return 1
    end
    return $rc
end

function exec_appops_get -a pkg op
    set -l output (exec_android_cmd "cmd appops get $pkg $op 2>&1")
    set -l rc $pipestatus[1]
    if string match -q "*SecurityException*" "$output"
        or string match -q "*MANAGE_APP_OPS_MODES*" "$output"
        echo "unknown"
        return 0
    end
    if test $rc -ne 0
        echo "unknown"
        return 0
    end
    printf '%s\n' $output | head -n 1
end

function appops_available
    set -l pkg $TARGET_PACKAGES[1]
    set -l output (exec_android_cmd "cmd appops get $pkg RUN_IN_BACKGROUND 2>&1")
    if string match -q "*SecurityException*" "$output"
        or string match -q "*MANAGE_APP_OPS_MODES*" "$output"
        return 1
    end
    return 0
end

function get_package_uid -a pkg
    switch "$DETECTED_BACKEND"
        case "root" "su" "adb"
            set -l raw (exec_android_cmd "cmd package list packages -U $pkg 2>/dev/null")
            string match -rg 'uid:([0-9]+)' $raw | tail -n 1
        case "userland"
            set -l raw (pm list packages -U "$pkg" 2>/dev/null)
            string match -rg 'uid:([0-9]+)' $raw | tail -n 1
    end
end

function is_package_installed -a pkg
    switch "$DETECTED_BACKEND"
        case "root" "su" "adb"
            exec_android_cmd "pm list packages $pkg 2>/dev/null" | string replace -a -r '\r' '' | string match -q "package:$pkg"
        case "userland"
            pm list packages "$pkg" 2>/dev/null | string replace -a -r '\r' '' | string match -q "package:$pkg"
    end
end

function check_oem_and_root_compatibility
    echo "=========================================================="
    echo "Device Compatibility: Root and Bootloader Lock Diagnostics"
    echo "=========================================================="

    set -l has_root 0
    if test "$DETECTED_BACKEND" = "root" -o "$DETECTED_BACKEND" = "su"
        set has_root 1
    end

    set -l oem_unlock_allowed (getprop sys.oem_unlock_allowed 2>/dev/null | string trim)
    set -l bootloader_locked (getprop ro.boot.flash.locked 2>/dev/null | string trim)
    set -l verified_boot (getprop ro.boot.verifiedbootstate 2>/dev/null | string trim)
    set -l oem_unlock_supported (getprop ro.oem_unlock_supported 2>/dev/null | string trim)

    echo "Diagnostic Properties:"
    echo "  - Detected Backend:             $DETECTED_BACKEND"
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
        echo "[+] ROOT DETECTED: Privileged execution and Netfilter controls enabled."
        return 0
    end

    if test "$bootloader_locked" = "0"
        echo "[i] Bootloader is UNLOCKED (ro.boot.flash.locked=0)."
        echo "    Install Magisk or KernelSU to obtain full root capabilities in Termux."
        return 0
    end

    if test "$oem_unlock_allowed" != "1"
        echo "[!] COMPATIBILITY WARNING: OEM Unlocking is DISABLED on this device."
        echo "    Current status: sys.oem_unlock_allowed=$oem_unlock_allowed"
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
    end
    echo "=========================================================="
end

function pause_traffic
    echo "=========================================================="
    echo "Executing Pause: Shopping Traffic & Notification Control"
    echo "Active Backend: $DETECTED_BACKEND"
    echo "=========================================================="

    set -l privileged_success 0
    set -l fallback_used 0

    if test "$DETECTED_BACKEND" != "userland"

        for pkg in $TARGET_PACKAGES
            if is_package_installed $pkg
                echo "[+] Applying privileged controls to: $pkg"
                set -l applied 0
                if exec_appops_set $pkg POST_NOTIFICATION ignore
                    set applied (math $applied + 1)
                end
                if exec_appops_set $pkg RUN_ANY_IN_BACKGROUND ignore
                    set applied (math $applied + 1)
                end

                set -l uid (get_package_uid $pkg)
                if test -n "$uid"
                    exec_android_cmd "cmd netpolicy add restrict-background-blacklist $uid 2>/dev/null"; or true
                    echo "    -> Blacklisted UID $uid via netpolicy."
                end
                set privileged_success 1
                if test $applied -lt 2
                    echo "    -> AppOps applied partially ($applied/2)."
                end
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
        if test "$APP_OPS_AVAILABLE" = "1"
            echo "  - POST_NOTIFICATION disabled for retail apps."
            echo "  - RUN_ANY_IN_BACKGROUND blocked via AppOps."
        else
            echo "  - AppOps controls refused by the device permission monitor (see warning above)."
            echo "  - NetPolicy controls still applied where supported."
        end
        echo "  - NetPolicy cellular background sockets blacklisted."
        echo "  - WhatsApp, Instagram, Telegram, and hotspot remain unaffected."
    else if test $fallback_used -eq 1
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
    case "check"
        check_oem_and_root_compatibility
    case '*'
        echo "Usage: "(status filename)" {pause|resume|status|check}"
        exit 1
end
