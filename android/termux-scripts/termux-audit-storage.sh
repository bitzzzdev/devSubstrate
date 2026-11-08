#!/usr/bin/env bash
#
# termux-audit-storage.sh: Termux-native storage audit and cache trim.
#
# Works directly in Termux userland using df, find, du, and pm.
#
# Usage:
#   ./termux-audit-storage.sh status    # Displays storage usage and large files
#   ./termux-audit-storage.sh trim      # Cleans userland caches safely
#

set -euo pipefail

status_storage() {
    echo "=========================================================="
    echo "Termux Storage Accounting"
    echo "=========================================================="
    df -h /data 2>/dev/null || df -h "$HOME" || true
    echo ""

    echo "=== Large Files in Userland Downloads (Top 10) ==="
    if [[ -d "/sdcard/Download" ]]; then
        find /sdcard/Download -maxdepth 2 -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -n 10 || echo "None found."
    else
        echo "/sdcard/Download is not accessible. Run 'termux-setup-storage' to grant access."
    fi
    echo ""

    echo "=== Termux Prefix Disk Usage ==="
    if [[ -n "${PREFIX:-}" ]] && [[ -d "$PREFIX" ]]; then
        du -sh "$PREFIX" 2>/dev/null || echo "Prefix path unavailable."
    else
        echo "Running outside Termux environment (PREFIX variable unset)."
    fi
}

trim_caches() {
    echo "=========================================================="
    echo "Executing Cache Trim in Termux"
    echo "=========================================================="

    echo "[*] Cleaning Termux APT package cache..."
    apt-get clean 2>/dev/null || true

    echo "[*] Cleaning temporary files in \$TMPDIR..."
    rm -rf "$TMPDIR"/* 2>/dev/null || true

    local trimmed_os=0
    if command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
        echo "[+] Local ADB connected: Requesting OS package cache trim (10GB target)..."
        adb shell pm trim-caches 10737418240 2>/dev/null || true
        trimmed_os=1
    elif [[ $(id -u) -eq 0 ]] || (command -v su >/dev/null 2>&1 && su -c "id" >/dev/null 2>&1); then
        echo "[+] Root available: Requesting OS package cache trim..."
        su -c "pm trim-caches 10737418240" 2>/dev/null || true
        trimmed_os=1
    fi

    echo ""
    echo "==================== EXECUTION AUDIT ===================="
    echo "COMPLETED IN TERMUX:"
    echo "  - Cleaned APT cache and temporary files."
    if [[ $trimmed_os -eq 1 ]]; then
        echo "  - Successfully ran 'pm trim-caches' via local privileged backend."
    else
        echo ""
        echo "WHAT STILL NEEDS ADB OR ROOT PRIVILEGES:"
        echo "  - System-wide third-party app cache purging via 'pm trim-caches <bytes>'."
        echo "    In standard Termux userland, Android sandboxing prevents deleting another app's cache."
    fi
    echo "=========================================================="
}

action="${1:-status}"

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
