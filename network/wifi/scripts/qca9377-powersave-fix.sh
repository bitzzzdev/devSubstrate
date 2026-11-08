#!/usr/bin/env bash
#
# qca9377-powersave-fix.sh: Disables or re-enables Wi-Fi power saving for Qualcomm QCA9377.
#
# Usage:
#   sudo ./qca9377-powersave-fix.sh apply   # Disables Wi-Fi power saving and creates NM config
#   sudo ./qca9377-powersave-fix.sh revert  # Removes NM config and restores default power saving
#   ./qca9377-powersave-fix.sh status       # Checks current Wi-Fi interface power_save state
#

set -euo pipefail

NM_CONF="/etc/NetworkManager/conf.d/20-wifi-powersave-off.conf"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        exit 1
    fi
}

get_wifi_iface() {
    if command -v nmcli >/dev/null 2>&1; then
        nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}' || true
    else
        iw dev 2>/dev/null | awk '$1=="Interface" {print $2; exit}' || true
    fi
}

status_powersave() {
    local iface
    iface="$(get_wifi_iface)"
    echo "Wi-Fi Interface: ${iface:-none detected}"
    
    if [[ -n "$iface" ]] && command -v iw >/dev/null 2>&1; then
        echo "Current iw power save state:"
        iw dev "$iface" get power_save 2>/dev/null || echo "Unable to query power_save."
    fi

    echo ""
    echo "NetworkManager config status ($NM_CONF):"
    if [[ -f "$NM_CONF" ]]; then
        cat "$NM_CONF"
    else
        echo "Configuration file does not exist (default behavior active)."
    fi
}

apply_fix() {
    check_root
    local iface
    iface="$(get_wifi_iface)"

    if [[ -n "$iface" ]] && command -v iw >/dev/null 2>&1; then
        iw dev "$iface" set power_save off 2>/dev/null || true
        echo "Disabled runtime power save on $iface."
    fi

    mkdir -p /etc/NetworkManager/conf.d
    tee "$NM_CONF" >/dev/null <<'EOF'
[connection]
wifi.powersave = 2
EOF
    echo "Created persistent configuration at $NM_CONF (wifi.powersave = 2)."

    if systemctl is-active --quiet NetworkManager; then
        echo "Reloading NetworkManager..."
        systemctl reload NetworkManager 2>/dev/null || systemctl restart NetworkManager
    fi
    echo "Done. Wi-Fi power saving is disabled."
}

revert_fix() {
    check_root
    local iface
    iface="$(get_wifi_iface)"

    if [[ -f "$NM_CONF" ]]; then
        rm -f "$NM_CONF"
        echo "Removed $NM_CONF."
    else
        echo "$NM_CONF does not exist."
    fi

    if [[ -n "$iface" ]] && command -v iw >/dev/null 2>&1; then
        iw dev "$iface" set power_save on 2>/dev/null || true
        echo "Re-enabled runtime power save on $iface."
    fi

    if systemctl is-active --quiet NetworkManager; then
        echo "Reloading NetworkManager..."
        systemctl reload NetworkManager 2>/dev/null || systemctl restart NetworkManager
    fi
    echo "Done. Default Wi-Fi power saving restored."
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
        status_powersave
        ;;
    *)
        echo "Usage: $0 {apply|revert|status}"
        exit 1
        ;;
esac
