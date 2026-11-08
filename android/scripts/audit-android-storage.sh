#!/usr/bin/env bash
#
# audit-android-storage.sh: Inspects Android internal storage via ADB non-destructively.
#
# Usage:
#   ./audit-android-storage.sh status    # Displays storage usage, large files, and package cache
#   ./audit-android-storage.sh trim      # Trims filesystem caches safely without deleting user data
#

set -euo pipefail

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

status_storage() {
    echo "=== Android Storage Accounting (df -h /data) ==="
    adb shell df -h /data
    echo ""

    echo "=== Top 10 Largest User Files in /sdcard/Download ==="
    adb shell "find /sdcard/Download -maxdepth 2 -type f -exec ls -lh {} + 2>/dev/null" | sort -k5 -hr | head -n 10 || echo "No files found in Download."
    echo ""

    echo "=== Package Cache Candidates (Top 10 App Code/Cache Sizes) ==="
    adb shell "pm list packages -3" 2>/dev/null | head -n 10 | while read -r line; do
        pkg="${line#package:}"
        echo "Package: $pkg"
    done
}

trim_caches() {
    echo "Executing safe package manager cache trim request..."
    # pm trim-caches requests Android OS to clean expired cache across apps to free target bytes
    # Requesting 10GB trim (OS clears only what is safe and disposable)
    adb shell pm trim-caches 10737418240
    echo ""
    echo "Updated storage status:"
    adb shell df -h /data
}

action="${1:-status}"

check_adb

case "$action" in
    status)
        status_storage
        ;;
    trim)
        trim_caches
        ;;
    *)
        echo "Usage: $0 {status|trim}"
        exit 1
        ;;
esac
