#!/usr/bin/env bash
#
# uki-qca9377-fix.sh: Adds or removes pci=realloc=on in /etc/kernel/cmdline and regenerates UKI.
#
# Usage:
#   sudo ./uki-qca9377-fix.sh apply   # Adds pci=realloc=on and runs mkinitcpio -P
#   sudo ./uki-qca9377-fix.sh revert  # Removes pci=realloc=on and runs mkinitcpio -P
#   ./uki-qca9377-fix.sh status       # Checks current cmdline configuration
#

set -euo pipefail

CMDLINE_FILE="/etc/kernel/cmdline"
PARAM="pci=realloc=on"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        exit 1
    fi
}

check_cmdline_file() {
    if [[ ! -f "$CMDLINE_FILE" ]]; then
        echo "Error: $CMDLINE_FILE not found. Ensure this system uses UKI cmdline configuration." >&2
        exit 1
    fi
}

status_cmdline() {
    check_cmdline_file
    echo "Current /etc/kernel/cmdline:"
    cat "$CMDLINE_FILE"
    echo ""
    echo "Running /proc/cmdline:"
    cat /proc/cmdline
    echo ""
    if grep -qw "$PARAM" "$CMDLINE_FILE"; then
        echo "Status: $PARAM is configured in $CMDLINE_FILE."
    else
        echo "Status: $PARAM is NOT configured in $CMDLINE_FILE."
    fi
}

apply_fix() {
    check_root
    check_cmdline_file

    if grep -qw "$PARAM" "$CMDLINE_FILE"; then
        echo "$PARAM is already present in $CMDLINE_FILE."
    else
        cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.$(date +%s)"
        # Append parameter cleanly
        sed -i "s/$/ ${PARAM}/" "$CMDLINE_FILE"
        sed -i 's/[[:space:]]\+/ /g' "$CMDLINE_FILE"
        echo "Added $PARAM to $CMDLINE_FILE."
    fi

    echo "Regenerating Unified Kernel Images (mkinitcpio -P)..."
    mkinitcpio -P
    echo "Done. Reboot to apply changes."
}

revert_fix() {
    check_root
    check_cmdline_file

    if grep -qw "$PARAM" "$CMDLINE_FILE"; then
        cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.$(date +%s)"
        sed -i "s/\b${PARAM}\b//g" "$CMDLINE_FILE"
        sed -i 's/[[:space:]]\+/ /g' "$CMDLINE_FILE"
        sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "$CMDLINE_FILE"
        echo "Removed $PARAM from $CMDLINE_FILE."
        echo "Regenerating Unified Kernel Images (mkinitcpio -P)..."
        mkinitcpio -P
        echo "Done. Reboot to apply reverted configuration."
    else
        echo "$PARAM was not found in $CMDLINE_FILE. Nothing to revert."
    fi
}

action="${1:-}"

case "$action" in
    apply)
        apply_fix
        ;;
    revert)
        revert_fix
        ;;
    status)
        status_cmdline
        ;;
    *)
        echo "Usage: $0 {apply|revert|status}"
        exit 1
        ;;
esac
