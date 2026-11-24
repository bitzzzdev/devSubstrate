#!/usr/bin/env fish
#
# metered-connection-control.fish: Mark the active NetworkManager Wi-Fi
# profile as metered or restore automatic detection.
#
# Usage:
#   sudo fish ./metered-connection-control.fish apply
#   fish ./metered-connection-control.fish status
#   sudo fish ./metered-connection-control.fish revert
#

if not type -q nmcli
    echo "Error: nmcli was not found. This script requires NetworkManager." >&2
    exit 1
end

set -l action status
if test (count $argv) -gt 0
    set action $argv[1]
end

set -l uuid (nmcli -t -f UUID,TYPE connection show --active | awk -F: '$2 == "802-11-wireless" { print $1; exit }')
if test -z "$uuid"
    echo "Error: no active NetworkManager Wi-Fi connection was found." >&2
    echo "Connect through a NetworkManager-managed Wi-Fi profile first." >&2
    exit 1
end

set -l name (nmcli -g connection.id connection show "$uuid")

switch "$action"
    case apply
        if not nmcli connection modify "$uuid" connection.metered yes
            exit 1
        end
        echo "Marked Wi-Fi profile as metered: $name"
        echo "Compatible applications can now treat this connection as data-limited."
        echo "This does not block all background traffic or impose a hard data quota."
        echo "Metered setting:" (nmcli -g connection.metered connection show "$uuid")
    case revert
        if not nmcli connection modify "$uuid" connection.metered unknown
            exit 1
        end
        echo "Restored automatic metered detection for: $name"
        echo "Metered setting:" (nmcli -g connection.metered connection show "$uuid")
    case status
        echo "Active Wi-Fi profile: $name"
        echo "Profile UUID: $uuid"
        echo "Metered setting:" (nmcli -g connection.metered connection show "$uuid")
    case '*'
        echo "Usage: metered-connection-control.fish {apply|revert|status}" >&2
        exit 2
end
