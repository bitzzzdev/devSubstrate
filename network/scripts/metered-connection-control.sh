#!/usr/bin/env bash
#
# metered-connection-control.sh: Mark the active Wi-Fi profile as metered or
# restore NetworkManager's automatic metered-state detection.
#
# Usage:
#   sudo ./metered-connection-control.sh apply
#   ./metered-connection-control.sh status
#   sudo ./metered-connection-control.sh revert
#
set -euo pipefail

require_nmcli() {
    if ! command -v nmcli >/dev/null 2>&1; then
        echo "Error: nmcli was not found. This script requires NetworkManager." >&2
        exit 1
    fi
}

active_wifi_uuid() {
    nmcli -t -f UUID,TYPE connection show --active |
        awk -F: '$2 == "802-11-wireless" { print $1; exit }'
}

get_active_wifi_uuid() {
    local uuid
    uuid="$(active_wifi_uuid)"
    if [[ -z "$uuid" ]]; then
        echo "Error: no active NetworkManager Wi-Fi connection was found." >&2
        echo "Connect through a NetworkManager-managed Wi-Fi profile first." >&2
        return 1
    fi
    printf '%s\n' "$uuid"
}

show_status() {
    local uuid name metered
    uuid="$(get_active_wifi_uuid)" || return 1
    name="$(nmcli -g connection.id connection show "$uuid")"
    metered="$(nmcli -g connection.metered connection show "$uuid")"
    printf 'Active Wi-Fi profile: %s\n' "$name"
    printf 'Profile UUID: %s\n' "$uuid"
    printf 'Metered setting: %s\n' "$metered"
}

apply_metered() {
    local uuid name
    uuid="$(get_active_wifi_uuid)" || return 1
    name="$(nmcli -g connection.id connection show "$uuid")"
    nmcli connection modify "$uuid" connection.metered yes
    printf 'Marked Wi-Fi profile as metered: %s\n' "$name"
    echo "Compatible applications can now treat this connection as data-limited."
    echo "This does not block all background traffic or impose a hard data quota."
    show_status
}

revert_metered() {
    local uuid name
    uuid="$(get_active_wifi_uuid)" || return 1
    name="$(nmcli -g connection.id connection show "$uuid")"
    nmcli connection modify "$uuid" connection.metered unknown
    printf 'Restored automatic metered detection for: %s\n' "$name"
    show_status
}

require_nmcli
action="${1:-status}"

case "$action" in
    apply)
        apply_metered
        ;;
    revert)
        revert_metered
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {apply|revert|status}" >&2
        exit 2
        ;;
esac
