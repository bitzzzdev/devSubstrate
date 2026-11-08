#!/usr/bin/env bash
#
# vlc-ffmpeg-plugin-fix.sh: Installs or removes vlc-plugin-ffmpeg on Arch Linux.
#
# Usage:
#   sudo ./vlc-ffmpeg-plugin-fix.sh apply   # Installs vlc-plugin-ffmpeg
#   sudo ./vlc-ffmpeg-plugin-fix.sh revert  # Removes vlc-plugin-ffmpeg
#   ./vlc-ffmpeg-plugin-fix.sh status       # Checks if avcodec plugin exists
#

set -euo pipefail

PACKAGE="vlc-plugin-ffmpeg"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        exit 1
    fi
}

check_pacman() {
    if ! command -v pacman >/dev/null 2>&1; then
        echo "Error: pacman package manager not found. This fix applies to Arch Linux." >&2
        exit 1
    fi
}

status_plugin() {
    echo "Checking VLC FFmpeg avcodec plugin status:"
    local found
    found=$(find /usr/lib/vlc/plugins -name "*avcodec*" 2>/dev/null || true)
    if [[ -n "$found" ]]; then
        echo "Found active plugin:"
        echo "$found"
        echo "Status: H.264/FFmpeg decoding plugin is installed."
    else
        echo "Status: FFmpeg avcodec plugin not found in /usr/lib/vlc/plugins."
    fi

    if command -v pacman >/dev/null 2>&1; then
        echo ""
        pacman -Q "$PACKAGE" 2>/dev/null || echo "$PACKAGE is not currently installed via pacman."
    fi
}

apply_fix() {
    check_root
    check_pacman
    echo "Installing $PACKAGE via pacman..."
    pacman -S --needed --noconfirm "$PACKAGE"
    echo "Done. Restart VLC and test H.264 video playback."
}

revert_fix() {
    check_root
    check_pacman
    if pacman -Q "$PACKAGE" >/dev/null 2>&1; then
        echo "Removing $PACKAGE via pacman..."
        pacman -R --noconfirm "$PACKAGE"
        echo "Removed $PACKAGE."
    else
        echo "$PACKAGE is not installed. Nothing to revert."
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
        status_plugin
        ;;
    *)
        echo "Usage: $0 {apply|revert|status}"
        exit 1
        ;;
esac
