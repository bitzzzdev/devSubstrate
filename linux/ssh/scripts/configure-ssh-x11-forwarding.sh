#!/usr/bin/env bash
#
# configure-ssh-x11-forwarding.sh: Configures or reverts persistent X11 forwarding for gcloud/SSH.
#
# Usage:
#   ./configure-ssh-x11-forwarding.sh apply   # Adds gcssh alias and ~/.ssh/config ForwardX11 rules
#   ./configure-ssh-x11-forwarding.sh revert  # Removes added alias and reverts ~/.ssh/config
#   ./configure-ssh-x11-forwarding.sh status  # Inspects local SSH and alias configuration
#

set -euo pipefail

SSH_CONFIG="$HOME/.ssh/config"
BASHRC="$HOME/.bashrc"
ALIAS_LINE="alias gcssh='gcloud cloud-shell ssh --authorize-session --ssh-flag=\"-X\"'"
MARKER_START="# --- devSubstrate gcloud X11 start ---"
MARKER_END="# --- devSubstrate gcloud X11 end ---"

status_config() {
    echo "Inspecting local SSH X11 configuration:"
    echo "======================================"
    if [[ -f "$SSH_CONFIG" ]]; then
        echo "Found $SSH_CONFIG:"
        grep -E -i "ForwardX11" "$SSH_CONFIG" || echo "No ForwardX11 directives found in $SSH_CONFIG."
    else
        echo "$SSH_CONFIG does not exist."
    fi

    echo ""
    echo "Inspecting ~/.bashrc for gcssh alias:"
    if grep -q "alias gcssh=" "$BASHRC" 2>/dev/null; then
        grep "alias gcssh=" "$BASHRC"
    else
        echo "gcssh alias not found in $BASHRC."
    fi
}

apply_config() {
    echo "Applying persistent X11 configuration..."

    mkdir -p "$HOME/.ssh"
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"

    if grep -q "$MARKER_START" "$SSH_CONFIG"; then
        echo "X11 block already present in $SSH_CONFIG."
    else
        cat >> "$SSH_CONFIG" <<EOF

$MARKER_START
Host *.google.com *.internal
    ForwardX11 yes
    ForwardX11Trusted yes
$MARKER_END
EOF
        echo "Added ForwardX11 settings to $SSH_CONFIG."
    fi

    touch "$BASHRC"
    if grep -q "alias gcssh=" "$BASHRC"; then
        echo "gcssh alias already present in $BASHRC."
    else
        cat >> "$BASHRC" <<EOF

$MARKER_START
$ALIAS_LINE
$MARKER_END
EOF
        echo "Added gcssh alias to $BASHRC."
    fi

    echo "Done. Reload with 'source ~/.bashrc'."
}

revert_config() {
    echo "Reverting persistent X11 configuration..."

    if [[ -f "$SSH_CONFIG" ]] && grep -q "$MARKER_START" "$SSH_CONFIG"; then
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$SSH_CONFIG"
        echo "Removed X11 block from $SSH_CONFIG."
    else
        echo "No managed X11 block found in $SSH_CONFIG."
    fi

    if [[ -f "$BASHRC" ]] && grep -q "$MARKER_START" "$BASHRC"; then
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$BASHRC"
        echo "Removed gcssh alias from $BASHRC."
    else
        echo "No managed alias found in $BASHRC."
    fi

    echo "Done. Configuration reverted."
}

action="${1:-}"

case "$action" in
    apply)
        apply_config
        ;;
    revert)
        revert_config
        ;;
    status)
        status_config
        ;;
    *)
        echo "Usage: $0 {apply|revert|status}"
        exit 1
        ;;
esac
