#!/usr/bin/env fish
#
# vlc-ffmpeg-plugin-fix.fish: Fish shell script to install or remove vlc-plugin-ffmpeg.
#
# Usage:
#   sudo ./vlc-ffmpeg-plugin-fix.fish apply   # Installs vlc-plugin-ffmpeg
#   sudo ./vlc-ffmpeg-plugin-fix.fish revert  # Removes vlc-plugin-ffmpeg
#   ./vlc-ffmpeg-plugin-fix.fish status       # Checks if avcodec plugin exists
#

set -l PACKAGE "vlc-plugin-ffmpeg"

function check_root
    if test (id -u) -ne 0
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        return 1
    end
    return 0
end

function check_pacman
    if not command -v pacman >/dev/null 2>&1
        echo "Error: pacman package manager not found. This fix applies to Arch Linux." >&2
        return 1
    end
    return 0
end

function status_plugin
    echo "Checking VLC FFmpeg avcodec plugin status:"
    set -l found (find /usr/lib/vlc/plugins -name "*avcodec*" 2>/dev/null)
    if test -n "$found"
        echo "Found active plugin:"
        echo "$found"
        echo "Status: H.264/FFmpeg decoding plugin is installed."
    else
        echo "Status: FFmpeg avcodec plugin not found in /usr/lib/vlc/plugins."
    end

    if command -v pacman >/dev/null 2>&1
        echo ""
        pacman -Q "$PACKAGE" 2>/dev/null; or echo "$PACKAGE is not currently installed via pacman."
    end
end

function apply_fix
    if not check_root
        return 1
    end
    if not check_pacman
        return 1
    end
    echo "Installing $PACKAGE via pacman..."
    pacman -S --needed --noconfirm "$PACKAGE"
    echo "Done. Restart VLC and test H.264 video playback."
end

function revert_fix
    if not check_root
        return 1
    end
    if not check_pacman
        return 1
    end
    if pacman -Q "$PACKAGE" >/dev/null 2>&1
        echo "Removing $PACKAGE via pacman..."
        pacman -R --noconfirm "$PACKAGE"
        echo "Removed $PACKAGE."
    else
        echo "$PACKAGE is not installed. Nothing to revert."
    end
end

set -l action $argv[1]

switch "$action"
    case "apply"
        apply_fix
    case "revert"
        revert_fix
    case "status"
        status_plugin
    case '*'
        echo "Usage: "(status filename)" {apply|revert|status}"
        exit 1
end
