#!/usr/bin/env bash
#
# manage-shopping-traffic.sh: Reduce background data use from shopping and
# delivery apps over ADB while preserving hotspot forwarding and essential apps.
#
# Global Data Saver is deliberately kept OFF for hotspot compatibility.
# No notification permissions are changed.
#
# Usage:
#   ./manage-shopping-traffic.sh automate-ui  # Apply maximum shopping-app controls
#   ./manage-shopping-traffic.sh pause        # Alias for automate-ui
#   ./manage-shopping-traffic.sh resume       # Restore Android defaults
#   ./manage-shopping-traffic.sh status       # Inspect current state
#
set -Eeuo pipefail

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

check_adb() {
    command -v adb >/dev/null 2>&1 || {
        echo "Error: adb not found. Install Android platform-tools." >&2
        exit 1
    }
    adb get-state >/dev/null 2>&1 || {
        echo "Error: No authorized ADB device. Connect the phone and authorize USB/Wireless debugging." >&2
        exit 1
    }
}

is_package_installed() {
    adb shell pm list packages "$1" 2>/dev/null | tr -d '\r' | grep -Fxq "package:$1"
}

get_package_uid() {
    adb shell cmd package list packages -U "$1" 2>/dev/null |
        sed -n 's/.*uid:\([0-9][0-9]*\).*/\1/p' | head -n 1 | tr -d '\r'
}

set_hotspot_safe_defaults() {
    # 0 means tether_offload_disabled=false, so hardware offload remains enabled.
    if adb shell settings put global tether_offload_disabled 0 >/dev/null 2>&1; then
        echo "Tethering hardware offload: enabled (where supported)."
    else
        echo "Warning: Could not set tethering offload; existing device setting retained." >&2
    fi

    # Do not enable global Data Saver. It can interfere with tethered clients on
    # some Android/OEM builds. Per-app execution restrictions are used instead.
    adb shell cmd netpolicy set restrict-background false >/dev/null 2>&1 || {
        echo "Warning: Could not confirm global Data Saver is off." >&2
    }
}

pause_traffic() {
    echo "Applying maximum supported background restrictions to shopping apps..."
    set_hotspot_safe_defaults

    local found=0
    for pkg in "${TARGET_PACKAGES[@]}"; do
        if ! is_package_installed "$pkg"; then
            echo "Skip (not installed): $pkg"
            continue
        fi

        found=1
        echo "Restricting: $pkg"

        adb shell cmd appops set "$pkg" RUN_IN_BACKGROUND ignore >/dev/null 2>&1 ||
            echo "  Warning: RUN_IN_BACKGROUND not supported for $pkg" >&2
        adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1 ||
            echo "  Warning: RUN_ANY_IN_BACKGROUND not supported for $pkg" >&2
        adb shell cmd usagestats set-app-standby-bucket "$pkg" restricted >/dev/null 2>&1 ||
            echo "  Warning: restricted standby bucket unavailable for $pkg" >&2
        adb shell am force-stop "$pkg" >/dev/null 2>&1 ||
            echo "  Warning: could not force-stop $pkg" >&2
    done

    if [[ "$found" -eq 0 ]]; then
        echo "No target shopping apps are installed."
    fi

    echo
    echo "Applied. Shopping apps are force-stopped and background execution is restricted."
    echo "Foreground use remains possible when you manually open an app."
    echo "WhatsApp, Instagram, Telegram, Google Play Services, and hotspot routing were not targeted."
    echo "Note: this limits background activity, not data used while an app is open."
}

resume_traffic() {
    echo "Restoring Android default background behavior for target apps..."
    for pkg in "${TARGET_PACKAGES[@]}"; do
        if ! is_package_installed "$pkg"; then
            continue
        fi

        echo "Restoring: $pkg"
        adb shell cmd appops set "$pkg" RUN_IN_BACKGROUND default >/dev/null 2>&1 || true
        adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND default >/dev/null 2>&1 || true
        adb shell cmd usagestats set-app-standby-bucket "$pkg" active >/dev/null 2>&1 || true
    done

    echo "Restored Android default AppOps and active standby bucket for installed target apps."
    echo "Global Data Saver remains off to preserve hotspot compatibility."
}

show_status() {
    echo "=== Global Data Saver ==="
    adb shell cmd netpolicy get restrict-background 2>/dev/null || true
    echo
    echo "=== Tethering Offload Setting ==="
    adb shell settings get global tether_offload_disabled 2>/dev/null || true
    echo
    echo "=== Shopping App Restrictions ==="

    for pkg in "${TARGET_PACKAGES[@]}"; do
        if ! is_package_installed "$pkg"; then
            continue
        fi

        echo "Package: $pkg"
        adb shell cmd appops get "$pkg" RUN_IN_BACKGROUND 2>/dev/null | head -n 1 || true
        adb shell cmd appops get "$pkg" RUN_ANY_IN_BACKGROUND 2>/dev/null | head -n 1 || true
        adb shell cmd usagestats get-app-standby-bucket "$pkg" 2>/dev/null || true
    done
}

main() {
    local action="${1:-}"
    check_adb

    case "$action" in
        automate-ui|automate_ui|pause|apply)
            pause_traffic
            ;;
        resume|restore|revert)
            resume_traffic
            ;;
        status)
            show_status
            ;;
        -h|--help|help)
            sed -n '2,12p' "$0"
            ;;
        *)
            echo "Usage: $0 {automate-ui|pause|resume|status}" >&2
            exit 2
            ;;
    esac
}

main "$@"
