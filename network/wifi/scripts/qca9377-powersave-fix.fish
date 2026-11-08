#!/usr/bin/env fish
#
# qca9377-powersave-fix.fish: Fish shell script to disable or re-enable Wi-Fi power saving.
#
# Usage:
#   sudo ./qca9377-powersave-fix.fish apply   # Disables Wi-Fi power saving persistently
#   sudo ./qca9377-powersave-fix.fish revert  # Reverts to default power saving
#   ./qca9377-powersave-fix.fish status       # Checks current Wi-Fi power_save state
#

set -l NM_CONF "/etc/NetworkManager/conf.d/20-wifi-powersave-off.conf"

function check_root
    if test (id -u) -ne 0
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        return 1
    end
    return 0
end

function get_wifi_iface
    if command -v nmcli >/dev/null 2>&1
        nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}'
    else if command -v iw >/dev/null 2>&1
        iw dev 2>/dev/null | awk '$1=="Interface" {print $2; exit}'
    end
end

function status_powersave
    set -l iface (get_wifi_iface)
    echo "Wi-Fi Interface: "(test -n "$iface"; and echo "$iface"; or echo "none detected")

    if test -n "$iface"; and command -v iw >/dev/null 2>&1
        echo "Current iw power save state:"
        iw dev "$iface" get power_save 2>/dev/null; or echo "Unable to query power_save."
    end

    echo ""
    echo "NetworkManager config status ($NM_CONF):"
    if test -f "$NM_CONF"
        cat "$NM_CONF"
    else
        echo "Configuration file does not exist (default behavior active)."
    end
end

function apply_fix
    if not check_root
        return 1
    end
    set -l iface (get_wifi_iface)

    if test -n "$iface"; and command -v iw >/dev/null 2>&1
        iw dev "$iface" set power_save off 2>/dev/null; or true
        echo "Disabled runtime power save on $iface."
    end

    mkdir -p /etc/NetworkManager/conf.d
    echo "[connection]
wifi.powersave = 2" > "$NM_CONF"
    echo "Created persistent configuration at $NM_CONF (wifi.powersave = 2)."

    if systemctl is-active --quiet NetworkManager
        echo "Reloading NetworkManager..."
        systemctl reload NetworkManager 2>/dev/null; or systemctl restart NetworkManager
    end
    echo "Done. Wi-Fi power saving is disabled."
end

function revert_fix
    if not check_root
        return 1
    end
    set -l iface (get_wifi_iface)

    if test -f "$NM_CONF"
        rm -f "$NM_CONF"
        echo "Removed $NM_CONF."
    else
        echo "$NM_CONF does not exist."
    end

    if test -n "$iface"; and command -v iw >/dev/null 2>&1
        iw dev "$iface" set power_save on 2>/dev/null; or true
        echo "Re-enabled runtime power save on $iface."
    end

    if systemctl is-active --quiet NetworkManager
        echo "Reloading NetworkManager..."
        systemctl reload NetworkManager 2>/dev/null; or systemctl restart NetworkManager
    end
    echo "Done. Default Wi-Fi power saving restored."
end

set -l action $argv[1]

switch "$action"
    case "apply"
        apply_fix
    case "revert"
        revert_fix
    case "status"
        status_powersave
    case '*'
        echo "Usage: "(status filename)" {apply|revert|status}"
        exit 1
end
