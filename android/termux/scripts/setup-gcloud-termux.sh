#!/usr/bin/env bash
#
# setup-gcloud-termux.sh: Installs and configures Google Cloud SDK on Android Termux.
#
# Usage:
#   ./setup-gcloud-termux.sh apply    # Installs SDK and configures ~/.bashrc
#   ./setup-gcloud-termux.sh status   # Verifies installation, Python path, and CLI version
#   ./setup-gcloud-termux.sh revert   # Removes shell configuration blocks and aliases
#   curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.sh | bash
#

set -euo pipefail

BASHRC="$HOME/.bashrc"
MARKER_START="# --- devSubstrate gcloud termux start ---"
MARKER_END="# --- devSubstrate gcloud termux end ---"
SDK_DIR="$HOME/google-cloud-sdk"

status_gcloud() {
    echo "===== Google Cloud CLI Termux Status ====="
    echo "SDK directory: $SDK_DIR"
    if [[ -d "$SDK_DIR" ]]; then
        echo "[OK] SDK directory exists."
    else
        echo "[FAIL] SDK directory not found."
    fi

    echo "Python runtime:"
    if [[ -x "/data/data/com.termux/files/usr/bin/python" ]]; then
        echo "[OK] Termux Python found at /data/data/com.termux/files/usr/bin/python"
    else
        echo "[WARN] Termux Python binary missing. Install with 'pkg install python'."
    fi

    echo "Checking ~/.bashrc configuration:"
    if [[ -f "$BASHRC" ]] && grep -q "$MARKER_START" "$BASHRC"; then
        echo "[OK] Managed configuration block found in $BASHRC."
    else
        echo "[INFO] No managed configuration block in $BASHRC."
    fi

    if command -v gcloud >/dev/null 2>&1; then
        echo "[OK] gcloud executable available in PATH."
        gcloud --version 2>/dev/null || true
    else
        echo "[INFO] gcloud not yet in active PATH. Run 'source ~/.bashrc'."
    fi
}

apply_gcloud() {
    echo "===== Installing and Configuring Google Cloud SDK on Termux ====="
    echo

    if command -v pkg >/dev/null 2>&1; then
        echo "Installing prerequisites (python, curl, openssh)..."
        pkg update -y
        pkg install -y python curl openssh
    fi

    if [[ ! -d "$SDK_DIR" ]]; then
        echo "Downloading Google Cloud SDK installer..."
        curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
    else
        echo "Google Cloud SDK directory already exists at $SDK_DIR."
    fi

    if [[ -f "$SDK_DIR/install.sh" ]]; then
        echo "Configuring SDK without unsupported binary components..."
        "$SDK_DIR/install.sh" --override-components --quiet || true
    fi

    echo "Configuring $BASHRC..."
    touch "$BASHRC"

    if grep -q "$MARKER_START" "$BASHRC"; then
        echo "Configuration block already present in $BASHRC."
    else
        cat >> "$BASHRC" <<'EOF'

# --- devSubstrate gcloud termux start ---
export CLOUDSDK_PYTHON="/data/data/com.termux/files/usr/bin/python"
export PATH="$HOME/google-cloud-sdk/bin:$PATH"

if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then
    source "$HOME/google-cloud-sdk/path.bash.inc"
fi

if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then
    source "$HOME/google-cloud-sdk/completion.bash.inc"
fi

alias gcs='gcloud cloud-shell ssh --authorize-session'
alias cloudshell='gcloud cloud-shell ssh --authorize-session'
alias glogin='gcloud auth login --no-browser'
alias gaccounts='gcloud auth list'
alias gswitch='gcloud config set account'
# --- devSubstrate gcloud termux end ---
EOF
        echo "Added environment exports and aliases to $BASHRC."
    fi

    echo
    echo "========================================"
    echo "Setup complete. Run 'source ~/.bashrc' or reload Termux."
    echo "Use 'gcs' or 'cloudshell' to SSH into Google Cloud Shell."
    echo "========================================"
}

revert_gcloud() {
    echo "===== Reverting Google Cloud SDK Termux Configuration ====="
    if [[ -f "$BASHRC" ]] && grep -q "$MARKER_START" "$BASHRC"; then
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$BASHRC"
        echo "Removed configuration block from $BASHRC."
    else
        echo "No configuration block found in $BASHRC."
    fi
    echo "Note: $SDK_DIR remains on disk. To delete entirely, run: rm -rf $SDK_DIR"
    echo "Revert complete."
}

action="${1:-apply}"

case "$action" in
    apply)
        apply_gcloud
        ;;
    status)
        status_gcloud
        ;;
    revert)
        revert_gcloud
        ;;
    *)
        echo "Usage: $0 {apply|status|revert}"
        exit 1
        ;;
esac
