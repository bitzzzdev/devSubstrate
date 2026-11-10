#!/usr/bin/env bash
#
# manage-shopping-traffic.sh: Selectively pause or resume background data and notifications
# for retail, delivery, and non-essential Android applications via ADB.
#
# Leaves WhatsApp, Instagram, Telegram, Google Play Services, and Wi-Fi Hotspot intact.
#
# Usage:
#   ./manage-shopping-traffic.sh pause   # Restricts shopping apps
#   ./manage-shopping-traffic.sh resume  # Restores shopping apps
#   ./manage-shopping-traffic.sh status  # Inspects current restrictions
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
)

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

get_package_uid() {
    local pkg="$1"
    adb shell cmd package list packages -U "$pkg" 2>/dev/null | sed -n 's/.*uid:\([0-9]*\).*/\1/p' || true
}

is_package_installed() {
    local pkg="$1"
    adb shell pm list packages "$pkg" 2>/dev/null | grep -q "^package:$pkg$"
}

set_tethering_offload() {
    if adb shell settings put global tether_offload_disabled 0 >/dev/null 2>&1 &&
        [[ "$(adb shell settings get global tether_offload_disabled 2>/dev/null | tr -d '\r')" == "0" ]]; then
        echo "Confirmed tethering hardware offload enabled (0)."
    else
        echo "Warning: Android denied the tethering offload setting. Continuing with app restrictions." >&2
    fi
}

pause_traffic() {
    echo "Applying selective background and notification restrictions..."
    set_tethering_offload

    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            echo "Restricting: $pkg"
            adb shell cmd appops set "$pkg" POST_NOTIFICATION ignore
            adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore
            
            local uid
            uid="$(get_package_uid "$pkg")"
            if [[ -n "$uid" ]]; then
                adb shell cmd netpolicy add restrict-background-blacklist "$uid" 2>/dev/null || true
                echo "  -> AppOps restricted, UID $uid added to netpolicy blacklist."
            fi
        else
            echo "Skipping uninstalled package: $pkg"
        fi
    done

    echo "Finished. WhatsApp, Instagram, Telegram, and Hotspot routing remain unhindered."
}

resume_traffic() {
    echo "Restoring background activity and notifications..."

    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            echo "Restoring: $pkg"
            adb shell cmd appops set "$pkg" POST_NOTIFICATION allow
            adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND allow
            
            local uid
            uid="$(get_package_uid "$pkg")"
            if [[ -n "$uid" ]]; then
                adb shell cmd netpolicy remove restrict-background-blacklist "$uid" 2>/dev/null || true
                echo "  -> AppOps restored, UID $uid removed from netpolicy blacklist."
            fi
        else
            echo "Skipping uninstalled package: $pkg"
        fi
    done

    echo "Finished. Default settings restored."
}

show_status() {
    echo "Inspecting current restrictions for target packages:"
    echo "===================================================="
    for pkg in "${TARGET_PACKAGES[@]}"; do
        if is_package_installed "$pkg"; then
            local post_notif
            local run_bg
            post_notif="$(adb shell cmd appops get "$pkg" POST_NOTIFICATION 2>/dev/null | head -n 1 || echo "unknown")"
            run_bg="$(adb shell cmd appops get "$pkg" RUN_ANY_IN_BACKGROUND 2>/dev/null | head -n 1 || echo "unknown")"
            echo "Package: $pkg"
            echo "  POST_NOTIFICATION:   $post_notif"
            echo "  RUN_ANY_IN_BACKGROUND: $run_bg"
        fi
    done
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
        *)
            echo "Usage: $0 {pause|resume|status}"
            exit 1
            ;;
    esac
}

main "$@"
