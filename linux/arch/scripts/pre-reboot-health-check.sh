#!/usr/bin/env bash
#
# pre-reboot-health-check.sh: Validates /boot, kernel, and UKI integrity before rebooting Arch Linux.
#
# Usage:
#   ./pre-reboot-health-check.sh
#   curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/pre-reboot-health-check.sh | bash
#   curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/pre-reboot-health-check.sh | bash
#

set -euo pipefail

echo "===== ARCH /BOOT PRE-REBOOT HEALTH CHECK ====="
echo

FAILED=0

echo ">>> /boot mount"
if mountpoint -q /boot; then
    echo "[OK] /boot is mounted"
else
    echo "[FAIL] /boot is NOT mounted"
    FAILED=1
fi

echo
echo ">>> /boot filesystem"
BOOT_FS=$(findmnt -n -o FSTYPE /boot 2>/dev/null || true)
if [ "$BOOT_FS" = "vfat" ]; then
    echo "[OK] /boot is VFAT"
else
    echo "[FAIL] /boot filesystem could not be verified as VFAT (detected: ${BOOT_FS:-none})"
    FAILED=1
fi

echo
echo ">>> Linux Kernel"
if sudo test -s /boot/vmlinuz-linux; then
    SIZE=$(sudo stat -c '%s' /boot/vmlinuz-linux)
    if [ "$SIZE" -gt 1000000 ]; then
        echo "[OK] vmlinuz-linux exists: $((SIZE / 1024 / 1024)) MB"
    else
        echo "[FAIL] vmlinuz-linux is suspiciously small (${SIZE} bytes)"
        FAILED=1
    fi
else
    echo "[FAIL] /boot/vmlinuz-linux is missing"
    FAILED=1
fi

echo
echo ">>> Unified Kernel Image (UKI)"
UKI="/boot/EFI/Linux/arch-linux.efi"
if sudo test -s "$UKI"; then
    SIZE=$(sudo stat -c '%s' "$UKI")
    if [ "$SIZE" -gt 1000000 ]; then
        echo "[OK] arch-linux.efi exists: $((SIZE / 1024 / 1024)) MB"
    else
        echo "[FAIL] arch-linux.efi is suspiciously small (${SIZE} bytes)"
        FAILED=1
    fi

    echo
    echo ">>> UKI format"
    UKI_TYPE=$(sudo file "$UKI" 2>/dev/null || true)
    if echo "$UKI_TYPE" | grep -qiE 'PE32\+.*EFI|EFI.*application'; then
        echo "[OK] UKI is a valid EFI executable"
    else
        echo "[FAIL] UKI is not recognized as an EFI executable"
        echo "$UKI_TYPE"
        FAILED=1
    fi
else
    echo "[FAIL] /boot/EFI/Linux/arch-linux.efi is missing"
    FAILED=1
fi

echo
echo ">>> AMD microcode"
if command -v pacman >/dev/null 2>&1 && pacman -Q amd-ucode >/dev/null 2>&1; then
    if sudo test -s /boot/amd-ucode.img; then
        echo "[OK] AMD microcode exists"
    else
        echo "[FAIL] /boot/amd-ucode.img is missing"
        FAILED=1
    fi
else
    echo "[INFO] amd-ucode is not installed or pacman not available"
fi

echo
echo ">>> Linux package integrity"
if command -v pacman >/dev/null 2>&1; then
    KERNEL_CHECK=$(pacman -Qk linux 2>&1 || true)
    if echo "$KERNEL_CHECK" | grep -qE '[1-9][0-9]* missing files'; then
        echo "[FAIL] Linux package has missing files"
        echo "$KERNEL_CHECK" | grep 'missing files'
        FAILED=1
    else
        echo "[OK] Linux package files are intact"
    fi
fi

echo
echo "========================================"
if [ "$FAILED" -eq 0 ]; then
    echo "[PASS] /boot CHECK PASSED"
    echo
    echo "Kernel and boot files look healthy."
    echo "Safe to reboot."
    echo "========================================"
    exit 0
else
    echo "[FAIL] /boot CHECK FAILED"
    echo
    echo "DO NOT reboot yet."
    echo "Investigate the [FAIL] item above."
    echo "========================================"
    exit 1
fi
