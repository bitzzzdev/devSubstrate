#!/usr/bin/env fish
#
# uki-qca9377-fix.fish: Fish shell script to apply or revert pci=realloc=on in UKI cmdline.
#
# Usage:
#   sudo ./uki-qca9377-fix.fish apply   # Adds pci=realloc=on and regenerates UKI
#   sudo ./uki-qca9377-fix.fish revert  # Removes pci=realloc=on and regenerates UKI
#   ./uki-qca9377-fix.fish status       # Checks current configuration
#

set -l CMDLINE_FILE "/etc/kernel/cmdline"
set -l PARAM "pci=realloc=on"

function check_root
    if test (id -u) -ne 0
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        return 1
    end
    return 0
end

function check_cmdline_file
    if not test -f "$CMDLINE_FILE"
        echo "Error: $CMDLINE_FILE not found. Ensure this system uses UKI cmdline configuration." >&2
        return 1
    end
    return 0
end

function status_cmdline
    if not check_cmdline_file
        return 1
    end
    echo "Current /etc/kernel/cmdline:"
    cat "$CMDLINE_FILE"
    echo ""
    echo "Running /proc/cmdline:"
    cat /proc/cmdline
    echo ""
    if grep -qw "$PARAM" "$CMDLINE_FILE"
        echo "Status: $PARAM is configured in $CMDLINE_FILE."
    else
        echo "Status: $PARAM is NOT configured in $CMDLINE_FILE."
    end
end

function apply_fix
    if not check_root
        return 1
    end
    if not check_cmdline_file
        return 1
    end

    if grep -qw "$PARAM" "$CMDLINE_FILE"
        echo "$PARAM is already present in $CMDLINE_FILE."
    else
        cp "$CMDLINE_FILE" "$CMDLINE_FILE.bak."(date +%s)
        sed -i "s/\$/ $PARAM/" "$CMDLINE_FILE"
        sed -i 's/[[:space:]]\+/ /g' "$CMDLINE_FILE"
        echo "Added $PARAM to $CMDLINE_FILE."
    end

    echo "Regenerating Unified Kernel Images (mkinitcpio -P)..."
    mkinitcpio -P
    echo "Done. Reboot to apply changes."
end

function revert_fix
    if not check_root
        return 1
    end
    if not check_cmdline_file
        return 1
    end

    if grep -qw "$PARAM" "$CMDLINE_FILE"
        cp "$CMDLINE_FILE" "$CMDLINE_FILE.bak."(date +%s)
        sed -i "s/\b$PARAM\b//g" "$CMDLINE_FILE"
        sed -i 's/[[:space:]]\+/ /g' "$CMDLINE_FILE"
        sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "$CMDLINE_FILE"
        echo "Removed $PARAM from $CMDLINE_FILE."
        echo "Regenerating Unified Kernel Images (mkinitcpio -P)..."
        mkinitcpio -P
        echo "Done. Reboot to apply reverted configuration."
    else
        echo "$PARAM was not found in $CMDLINE_FILE. Nothing to revert."
    end
end

set -l action $argv[1]

switch "$action"
    case "apply"
        apply_fix
    case "revert"
        revert_fix
    case "status"
        status_cmdline
    case '*'
        echo "Usage: "(status filename)" {apply|revert|status}"
        exit 1
end
