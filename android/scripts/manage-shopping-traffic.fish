#!/usr/bin/env fish
#
# manage-shopping-traffic.fish: Fish shell script to selectively pause or resume
# background data and notifications for shopping, quick commerce, and delivery apps via ADB.
#
# Preserves WhatsApp, Instagram, Telegram, Google Play Services, and Wi-Fi Hotspot.
#
# Usage:
#   ./manage-shopping-traffic.fish pause   # Restricts shopping apps
#   ./manage-shopping-traffic.fish resume  # Restores shopping apps
#   ./manage-shopping-traffic.fish status  # Displays current restriction status
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
    com.application.zomato

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

function get_package_uid -a pkg
    set -l raw (adb shell cmd package list packages -U $pkg 2>/dev/null)
    string match -r 'uid:([0-9]+)' $raw | tail -n 1
end

function is_package_installed -a pkg
    adb shell pm list packages $pkg 2>/dev/null | string match -q "package:$pkg"
end

function pause_traffic
    echo "Applying selective background and notification restrictions..."

    # Ensure tethering hardware offload is enabled
    adb shell settings put global tether_offload_disabled 0
    echo "Confirmed tethering hardware offload enabled (0)."

    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            echo "Restricting: $pkg"
            adb shell cmd appops set $pkg POST_NOTIFICATION ignore
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore

            set -l uid (get_package_uid $pkg)
            if test -n "$uid"
                adb shell cmd netpolicy add restrict-background-blacklist $uid 2>/dev/null
                echo "  -> AppOps restricted, UID $uid added to netpolicy blacklist."
            end
        else
            echo "Skipping uninstalled package: $pkg"
        end
    end

    echo "Finished. WhatsApp, Instagram, Telegram, and Hotspot routing remain unhindered."
end

function resume_traffic
    echo "Restoring background activity and notifications..."

    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            echo "Restoring: $pkg"
            adb shell cmd appops set $pkg POST_NOTIFICATION allow
            adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND allow

            set -l uid (get_package_uid $pkg)
            if test -n "$uid"
                adb shell cmd netpolicy remove restrict-background-blacklist $uid 2>/dev/null
                echo "  -> AppOps restored, UID $uid removed from netpolicy blacklist."
            end
        else
            echo "Skipping uninstalled package: $pkg"
        end
    end

    echo "Finished. Default settings restored."
end

function show_status
    echo "Inspecting current restrictions for target packages:"
    echo "===================================================="
    for pkg in $TARGET_PACKAGES
        if is_package_installed $pkg
            set -l post_notif (adb shell cmd appops get $pkg POST_NOTIFICATION 2>/dev/null | head -n 1)
            set -l run_bg (adb shell cmd appops get $pkg RUN_ANY_IN_BACKGROUND 2>/dev/null | head -n 1)
            echo "Package: $pkg"
            echo "  POST_NOTIFICATION:     $post_notif"
            echo "  RUN_ANY_IN_BACKGROUND: $run_bg"
        end
    end
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
    case '*'
        echo "Usage: "(status filename)" {pause|resume|status}"
        exit 1
end
