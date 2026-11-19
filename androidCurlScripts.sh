#!/usr/bin/env bash

set -euo pipefail

SOURCE_REF="${DEVSUBSTRATE_REF:-dev}"
REMOTE="${DEVSUBSTRATE_REMOTE:-github}"
case "$REMOTE" in
    github)
        BASE_URL="https://raw.githubusercontent.com/bitzzdev/devSubstrate/${SOURCE_REF}"
        ;;
    gitlab)
        BASE_URL="https://gitlab.com/bitzzdev/devSubstrate/-/raw/${SOURCE_REF}"
        ;;
    *)
        echo "Error: DEVSUBSTRATE_REMOTE must be 'github' or 'gitlab' (got '$REMOTE')." >&2
        exit 1
        ;;
esac

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

has_adb_device() {
    command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1
}

show_menu() {
    cat <<'MENU'
Android curl scripts

1. Device information
2. Reduce internet drainage
3. Revert specific changes
4. Storage maintenance
5. Install or configure Termux tools

Pass a number to run an option without the menu. Option 2 defaults to all restrictions.
MENU
}

run_device_info() {
    if has_adb_device; then
        run_remote android/scripts/audit-android-storage.sh status
    else
        run_remote android/termux-scripts/termux-audit-storage.sh status
    fi
}

run_drainage_reduction() {
    local target="${1:-all}"

    case "$target" in
        shopping)
            if has_adb_device; then
                run_remote android/scripts/manage-shopping-traffic.sh pause
            else
                run_remote android/termux-scripts/termux-manage-shopping-traffic.sh pause
            fi
            ;;
        hotspot)
            if has_adb_device; then
                run_remote network/scripts/hotspot-background-traffic-control.sh apply
            else
                run_remote android/termux-scripts/termux-hotspot-traffic-control.sh apply
            fi
            ;;
        all)
            run_drainage_reduction shopping
            run_drainage_reduction hotspot
            ;;
        *)
            echo "Usage: $0 2 {shopping|hotspot|all}" >&2
            exit 1
            ;;
    esac
}

run_revert() {
    local target="${1:-}"
    target="${target:-$(read_choice 'Choose shopping, hotspot, or gcloud: ')}"

    case "$target" in
        shopping)
            if has_adb_device; then
                run_remote android/scripts/manage-shopping-traffic.sh resume
            else
                run_remote android/termux-scripts/termux-manage-shopping-traffic.sh resume
            fi
            ;;
        hotspot)
            if has_adb_device; then
                run_remote network/scripts/hotspot-background-traffic-control.sh revert
            else
                run_remote android/termux-scripts/termux-hotspot-traffic-control.sh revert
            fi
            ;;
        gcloud)
            run_remote android/termux/scripts/setup-gcloud-termux.sh revert
            ;;
        *)
            echo "Usage: $0 3 {shopping|hotspot|gcloud}" >&2
            exit 1
            ;;
    esac
}

run_storage() {
    local action="${1:-}"
    action="${action:-$(read_choice 'Choose status or trim: ')}"
    case "$action" in
        status|trim)
            if has_adb_device; then
                run_remote android/scripts/audit-android-storage.sh "$action"
            else
                run_remote android/termux-scripts/termux-audit-storage.sh "$action"
            fi
            ;;
        *)
            echo "Usage: $0 4 {status|trim}" >&2
            exit 1
            ;;
    esac
}

run_termux_tool() {
    local target="${1:-}"
    target="${target:-$(read_choice 'Choose claude or gcloud: ')}"
    case "$target" in
        claude)
            run_remote android/termux/scripts/install-claude-code-termux.sh
            ;;
        gcloud)
            run_remote android/termux/scripts/setup-gcloud-termux.sh apply
            ;;
        *)
            echo "Usage: $0 5 {claude|gcloud}" >&2
            exit 1
            ;;
    esac
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
        run_storage "${2:-}"
        ;;
    5)
        run_termux_tool "${2:-}"
        ;;
    *)
        echo "Usage: $0 {1|2|3|4|5} [target]" >&2
        echo "Option 2 targets: shopping, hotspot, all (default: all)." >&2
        exit 1
        ;;
esac
