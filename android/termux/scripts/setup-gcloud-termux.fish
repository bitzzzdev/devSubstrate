#!/usr/bin/env fish
#
# setup-gcloud-termux.fish: Configures Google Cloud SDK environment for Fish shell on Android Termux.
#
# Usage:
#   fish setup-gcloud-termux.fish apply
#   fish setup-gcloud-termux.fish status
#   fish setup-gcloud-termux.fish revert
#   curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.fish | fish -s -- apply
#   curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/setup-gcloud-termux.fish | fish -s -- apply
#

set -l FISH_CONF "$HOME/.config/fish/config.fish"
set -l MARKER_START "# --- devSubstrate gcloud termux start ---"
set -l MARKER_END "# --- devSubstrate gcloud termux end ---"
set -l SDK_DIR "$HOME/google-cloud-sdk"

function status_gcloud
    echo "===== Google Cloud CLI Termux Status (Fish) ====="
    echo "SDK directory: $SDK_DIR"
    if test -d "$SDK_DIR"
        echo "[OK] SDK directory exists."
    else
        echo "[FAIL] SDK directory not found."
    end

    if test -x "/data/data/com.termux/files/usr/bin/python"
        echo "[OK] Termux Python found at /data/data/com.termux/files/usr/bin/python"
    else
        echo "[WARN] Termux Python binary missing. Install with 'pkg install python'."
    end

    if test -f "$FISH_CONF"; and grep -q "$MARKER_START" "$FISH_CONF"
        echo "[OK] Managed configuration block found in $FISH_CONF."
    else
        echo "[INFO] No managed configuration block in $FISH_CONF."
    end

    if command -v gcloud >/dev/null 2>&1
        echo "[OK] gcloud executable available in PATH."
        gcloud --version 2>/dev/null
    else
        echo "[INFO] gcloud not yet in active PATH."
    end
end

function apply_gcloud
    echo "===== Configuring Google Cloud SDK for Fish on Termux ====="
    if command -v pkg >/dev/null 2>&1
        echo "Installing prerequisites (python, curl, openssh)..."
        pkg update -y
        pkg install -y python curl openssh
    end

    if not test -d "$SDK_DIR"
        echo "Downloading Google Cloud SDK installer..."
        curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
    end

    mkdir -p "$HOME/.config/fish"
    touch "$FISH_CONF"

    if grep -q "$MARKER_START" "$FISH_CONF"
        echo "Configuration block already present in $FISH_CONF."
    else
        printf "\n%s\n" "$MARKER_START" >> "$FISH_CONF"
        echo 'set -gx CLOUDSDK_PYTHON "/data/data/com.termux/files/usr/bin/python"' >> "$FISH_CONF"
        echo 'fish_add_path "$HOME/google-cloud-sdk/bin"' >> "$FISH_CONF"
        echo "abbr -a gcs 'gcloud cloud-shell ssh --authorize-session'" >> "$FISH_CONF"
        echo "abbr -a cloudshell 'gcloud cloud-shell ssh --authorize-session'" >> "$FISH_CONF"
        echo "abbr -a glogin 'gcloud auth login --no-browser'" >> "$FISH_CONF"
        echo "abbr -a gaccounts 'gcloud auth list'" >> "$FISH_CONF"
        echo "abbr -a gswitch 'gcloud config set account'" >> "$FISH_CONF"
        printf "%s\n" "$MARKER_END" >> "$FISH_CONF"
        echo "Added environment exports and abbreviations to $FISH_CONF."
    end

    echo
    echo "========================================"
    echo "Setup complete. Reload Fish or run 'source $FISH_CONF'."
    echo "========================================"
end

function revert_gcloud
    echo "===== Reverting Google Cloud SDK Fish Configuration ====="
    if test -f "$FISH_CONF"; and grep -q "$MARKER_START" "$FISH_CONF"
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$FISH_CONF"
        echo "Removed configuration block from $FISH_CONF."
    else
        echo "No configuration block found in $FISH_CONF."
    end
    echo "Revert complete."
end

set -l action $argv[1]
if test -z "$action"
    set action "apply"
end

switch "$action"
    case apply
        apply_gcloud
    case status
        status_gcloud
    case revert
        revert_gcloud
    case '*'
        echo "Usage: "(status filename)" {apply|status|revert}"
        exit 1
end
