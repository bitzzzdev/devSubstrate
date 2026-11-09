#!/usr/bin/env fish
#
# pre-reboot-health-check.fish: Validates /boot, kernel, and UKI integrity before rebooting Arch Linux.
#
# Usage:
#   fish pre-reboot-health-check.fish
#   curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/pre-reboot-health-check.fish | fish
#

echo "===== ARCH /BOOT PRE-REBOOT HEALTH CHECK ====="
echo

set -l FAILED 0

echo ">>> /boot mount"
if mountpoint -q /boot
    echo "[OK] /boot is mounted"
else
    echo "[FAIL] /boot is NOT mounted"
    set FAILED 1
end

echo
echo ">>> /boot filesystem"
set -l BOOT_FS (findmnt -n -o FSTYPE /boot 2>/dev/null)
if test "$BOOT_FS" = "vfat"
    echo "[OK] /boot is VFAT"
else
    echo "[FAIL] /boot filesystem could not be verified as VFAT (detected: $BOOT_FS)"
    set FAILED 1
end

echo
echo ">>> Linux Kernel"
if sudo test -s /boot/vmlinuz-linux
    set -l SIZE (sudo stat -c '%s' /boot/vmlinuz-linux)
    if test $SIZE -gt 1000000
        set -l MB (math "floor($SIZE / 1024 / 1024)")
        echo "[OK] vmlinuz-linux exists: $MB MB"
    else
        echo "[FAIL] vmlinuz-linux is suspiciously small ($SIZE bytes)"
        set FAILED 1
    end
else
    echo "[FAIL] /boot/vmlinuz-linux is missing"
    set FAILED 1
end

echo
echo ">>> Unified Kernel Image (UKI)"
set -l UKI /boot/EFI/Linux/arch-linux.efi
if sudo test -s $UKI
    set -l SIZE (sudo stat -c '%s' $UKI)
    if test $SIZE -gt 1000000
        set -l MB (math "floor($SIZE / 1024 / 1024)")
        echo "[OK] arch-linux.efi exists: $MB MB"
    else
        echo "[FAIL] arch-linux.efi is suspiciously small ($SIZE bytes)"
        set FAILED 1
    end

    echo
    echo ">>> UKI format"
    set -l UKI_TYPE (sudo file $UKI 2>/dev/null)
    if string match -rq 'PE32\+.*EFI|EFI.*application' -- $UKI_TYPE
        echo "[OK] UKI is a valid EFI executable"
    else
        echo "[FAIL] UKI is not recognized as an EFI executable"
        echo "$UKI_TYPE"
        set FAILED 1
    end
else
    echo "[FAIL] /boot/EFI/Linux/arch-linux.efi is missing"
    set FAILED 1
end

echo
echo ">>> AMD microcode"
if command -v pacman >/dev/null 2>&1; and pacman -Q amd-ucode >/dev/null 2>&1
    if sudo test -s /boot/amd-ucode.img
        echo "[OK] AMD microcode exists"
    else
        echo "[FAIL] /boot/amd-ucode.img is missing"
        set FAILED 1
    end
else
    echo "[INFO] amd-ucode is not installed or pacman not available"
end

echo
echo ">>> Linux package integrity"
if command -v pacman >/dev/null 2>&1
    set -l KERNEL_CHECK (pacman -Qk linux 2>&1)
    if printf '%s\n' $KERNEL_CHECK | grep -qE '[1-9][0-9]* missing files'
        echo "[FAIL] Linux package has missing files"
        printf '%s\n' $KERNEL_CHECK | grep 'missing files'
        set FAILED 1
    else
        echo "[OK] Linux package files are intact"
    end
end

echo
echo "========================================"
if test $FAILED -eq 0
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
end
