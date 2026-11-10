#!/usr/bin/env bash

set -euo pipefail

SOURCE_REF="${DEVSUBSTRATE_REF:-dev}"
BASE_URL="https://raw.githubusercontent.com/bitzzdev/devSubstrate/${SOURCE_REF}"

run_remote() {
    local path="$1"
    shift
    curl -fsSL "$BASE_URL/$path" | bash -s -- "$@"
}

read_choice() {
    local prompt="$1"
    local choice
    if [[ ! -r /dev/tty ]]; then
        echo "Error: choose an option by passing it as an argument." >&2
        exit 1
    fi
    printf '%s' "$prompt" > /dev/tty
    read -r choice < /dev/tty
    printf '%s\n' "$choice"
}

show_menu() {
    cat <<'MENU'
Linux curl scripts

1. Device information
2. Reduce network drainage
3. Revert specific changes
4. Apply a system fix
5. Manage a sudo user
6. Install Legacy Launcher

Pass a number to run an option without the menu.
MENU
}

run_device_info() {
    run_remote linux/arch/scripts/pre-reboot-health-check.sh
}

run_drainage_reduction() {
    local target="${1:-}"
    target="${target:-$(read_choice 'Choose hotspot or wifi: ')}"
    case "$target" in
        hotspot)
            run_remote network/scripts/hotspot-background-traffic-control.sh apply
            ;;
        wifi)
            run_remote network/wifi/scripts/qca9377-powersave-fix.sh apply
            ;;
        *)
            echo "Usage: $0 2 {hotspot|wifi}" >&2
            exit 1
            ;;
    esac
}

run_revert() {
    local target="${1:-}"
    target="${target:-$(read_choice 'Choose hotspot, wifi, uki, vlc, or ssh: ')}"
    case "$target" in
        hotspot)
            run_remote network/scripts/hotspot-background-traffic-control.sh revert
            ;;
        wifi)
            run_remote network/wifi/scripts/qca9377-powersave-fix.sh revert
            ;;
        uki)
            run_remote linux/arch/scripts/uki-qca9377-fix.sh revert
            ;;
        vlc)
            run_remote linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh revert
            ;;
        ssh)
            run_remote linux/ssh/scripts/configure-ssh-x11-forwarding.sh revert
            ;;
        *)
            echo "Usage: $0 3 {hotspot|wifi|uki|vlc|ssh}" >&2
            exit 1
            ;;
    esac
}

run_system_fix() {
    local target="${1:-}"
    target="${target:-$(read_choice 'Choose uki, vlc, or ssh: ')}"
    case "$target" in
        uki)
            run_remote linux/arch/scripts/uki-qca9377-fix.sh apply
            ;;
        vlc)
            run_remote linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh apply
            ;;
        ssh)
            run_remote linux/ssh/scripts/configure-ssh-x11-forwarding.sh apply
            ;;
        *)
            echo "Usage: $0 4 {uki|vlc|ssh}" >&2
            exit 1
            ;;
    esac
}

run_sudo_user() {
    local action="${1:-}"
    local username="${2:-}"
    action="${action:-$(read_choice 'Choose create, status, or remove: ')}"
    if [[ -z "$username" ]]; then
        username="$(read_choice 'Enter username: ')"
    fi
    run_remote linux/arch/scripts/manage-sudo-user.sh "$action" "$username"
}

choice="${1:-}"
if [[ -z "$choice" ]]; then
    show_menu
    choice="$(read_choice 'Select an option: ')"
fi

case "$choice" in
    1)
        run_device_info
        ;;
    2)
        run_drainage_reduction "${2:-}"
        ;;
    3)
        run_revert "${2:-}"
        ;;
    4)
        run_system_fix "${2:-}"
        ;;
    5)
        run_sudo_user "${2:-}" "${3:-}"
        ;;
    6)
        run_remote linux/scripts/install-legacy-launcher.sh
        ;;
    *)
        echo "Usage: $0 {1|2|3|4|5|6} [target] [value]" >&2
        exit 1
        ;;
esac
