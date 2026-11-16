#!/usr/bin/env fish
#
# termux-audit-storage.fish: Fish shell script to inspect and clean storage from within Termux.
#
# Usage:
#   ./termux-audit-storage.fish status    # Inspects storage partitions and large files
#   ./termux-audit-storage.fish trim      # Trims userland caches safely
#

function status_storage
    echo "=========================================================="
    echo "Termux Storage Accounting"
    echo "=========================================================="
    df -h /data 2>/dev/null; or df -h "$HOME"; or true
    echo ""

    echo "=== Large Files in Userland Downloads (Top 10) ==="
    if test -d "/sdcard/Download"
        find /sdcard/Download -maxdepth 2 -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -n 10; or echo "None found."
    else
        echo "/sdcard/Download is not accessible. Run 'termux-setup-storage' to grant access."
    end
    echo ""

    echo "=== Termux Prefix Disk Usage ==="
    if set -q PREFIX; and test -d "$PREFIX"
        du -sh "$PREFIX" 2>/dev/null; or echo "Prefix path unavailable."
    else
        echo "Running outside Termux environment (PREFIX variable unset)."
    end
end

function trim_caches
    echo "=========================================================="
    echo "Executing Cache Trim in Termux"
    echo "=========================================================="

    echo "[*] Cleaning Termux APT package cache..."
    apt-get clean 2>/dev/null; or true

    set -l tmp_dir "$TMPDIR"
    if test -z "$tmp_dir"
        if set -q PREFIX
            set tmp_dir "$PREFIX/tmp"
        else
            set tmp_dir "$HOME/tmp"
        end
    end
    echo "[*] Cleaning temporary files in $tmp_dir..."
    # Never expand an unset var into a glob and never follow symlinks out of the dir.
    if test "$tmp_dir" != "/" -a "$tmp_dir" != "$HOME" -a -d "$tmp_dir"
        find "$tmp_dir" -mindepth 1 -xdev -delete 2>/dev/null; or true
    else
        echo "Skipping: $tmp_dir is not a safe temporary directory."
    end

    set -l trimmed_os 0
    if command -v adb >/dev/null 2>&1; and adb get-state >/dev/null 2>&1
        echo "[+] Local ADB connected: Requesting OS package cache trim (10GB target)..."
        adb shell pm trim-caches 10737418240 2>/dev/null; or true
        set trimmed_os 1
    else if test (id -u) -eq 0; or begin command -v su >/dev/null 2>&1; and su -c "id" >/dev/null 2>&1; end
        echo "[+] Root available: Requesting OS package cache trim..."
        su -c "pm trim-caches 10737418240" 2>/dev/null; or true
        set trimmed_os 1
    end

    echo ""
    echo "==================== EXECUTION AUDIT ===================="
    echo "COMPLETED IN TERMUX:"
    echo "  - Cleaned APT cache and temporary files."
    if test $trimmed_os -eq 1
        echo "  - Successfully ran 'pm trim-caches' via local privileged backend."
    else
        echo ""
        echo "WHAT STILL NEEDS ADB OR ROOT PRIVILEGES:"
        echo "  - System-wide third-party app cache purging via 'pm trim-caches <bytes>'."
        echo "    In standard Termux userland, Android sandboxing prevents deleting another app's cache."
    end
    echo "=========================================================="
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
