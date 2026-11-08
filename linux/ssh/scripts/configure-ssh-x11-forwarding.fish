#!/usr/bin/env fish
#
# configure-ssh-x11-forwarding.fish: Fish shell script to configure or revert persistent X11 forwarding.
#
# Usage:
#   ./configure-ssh-x11-forwarding.fish apply   # Adds gcssh abbreviation and ~/.ssh/config rules
#   ./configure-ssh-x11-forwarding.fish revert  # Erases gcssh abbreviation and cleans ~/.ssh/config
#   ./configure-ssh-x11-forwarding.fish status  # Displays current SSH config and abbr status
#

set -l SSH_CONFIG "$HOME/.ssh/config"
set -l MARKER_START "# --- devSubstrate gcloud X11 start ---"
set -l MARKER_END "# --- devSubstrate gcloud X11 end ---"

function status_config
    echo "Inspecting local SSH X11 configuration:"
    echo "======================================"
    if test -f "$SSH_CONFIG"
        echo "Found $SSH_CONFIG:"
        grep -E -i "ForwardX11" "$SSH_CONFIG"; or echo "No ForwardX11 directives found in $SSH_CONFIG."
    else
        echo "$SSH_CONFIG does not exist."
    end

    echo ""
    echo "Inspecting Fish abbreviations for gcssh:"
    abbr -l | grep -q "gcssh"; and abbr --show | grep "gcssh"; or echo "gcssh abbreviation not set in Fish."
end

function apply_config
    echo "Applying persistent X11 configuration..."

    mkdir -p "$HOME/.ssh"
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"

    if grep -q "$MARKER_START" "$SSH_CONFIG"
        echo "X11 block already present in $SSH_CONFIG."
    else
        echo "
$MARKER_START
Host *.google.com *.internal
    ForwardX11 yes
    ForwardX11Trusted yes
$MARKER_END" >> "$SSH_CONFIG"
        echo "Added ForwardX11 settings to $SSH_CONFIG."
    end

    abbr -a -- gcssh 'gcloud cloud-shell ssh --authorize-session --ssh-flag="-X"'
    echo "Saved persistent Fish abbreviation 'gcssh'."
    echo "Done. Typing 'gcssh' now automatically launches with X11 forwarding."
end

function revert_config
    echo "Reverting persistent X11 configuration..."

    if test -f "$SSH_CONFIG"; and grep -q "$MARKER_START" "$SSH_CONFIG"
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$SSH_CONFIG"
        echo "Removed X11 block from $SSH_CONFIG."
    else
        echo "No managed X11 block found in $SSH_CONFIG."
    end

    if abbr -l | grep -q "gcssh"
        abbr -e gcssh
        echo "Erased 'gcssh' Fish abbreviation."
    else
        echo "Abbreviation 'gcssh' was not found."
    end

    echo "Done. Configuration reverted."
end

set -l action $argv[1]

switch "$action"
    case "apply"
        apply_config
    case "revert"
        revert_config
    case "status"
        status_config
    case '*'
        echo "Usage: "(status filename)" {apply|revert|status}"
        exit 1
end
