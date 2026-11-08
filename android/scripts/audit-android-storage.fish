#!/usr/bin/env fish
#
# audit-android-storage.fish: Fish shell script to inspect and safely trim Android storage via ADB.
#
# Usage:
#   ./audit-android-storage.fish status    # Inspects partition usage and large download files
#   ./audit-android-storage.fish trim      # Requests safe OS-level cache trimming
#

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

function status_storage
    echo "=== Android Storage Accounting (df -h /data) ==="
    adb shell df -h /data
    echo ""

    echo "=== Top 10 Largest User Files in /sdcard/Download ==="
    adb shell "find /sdcard/Download -maxdepth 2 -type f -exec ls -lh {} + 2>/dev/null" | sort -k5 -hr | head -n 10; or echo "No files found in Download."
    echo ""

    echo "=== Third-Party Packages ==="
    adb shell "pm list packages -3" 2>/dev/null | head -n 10
end

function trim_caches
    echo "Executing safe package manager cache trim request..."
    # pm trim-caches requests Android OS to clean expired cache across apps to free target bytes
    adb shell pm trim-caches 10737418240
    echo ""
    echo "Updated storage status:"
    adb shell df -h /data
end

if not check_adb
    exit 1
end

set -l action $argv[1]
test -z "$action"; and set action "status"

switch "$action"
    case "status"
        status_storage
    case "trim"
        trim_caches
    case '*'
        echo "Usage: "(status filename)" {status|trim}"
        exit 1
end
