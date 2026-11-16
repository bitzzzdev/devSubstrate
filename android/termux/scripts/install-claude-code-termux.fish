#!/usr/bin/env fish
#
# install-claude-code-termux.fish: Installs compatible Claude Code CLI (v2.1.47) in Android Termux.
#
# Usage:
#   fish install-claude-code-termux.fish
#   curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/install-claude-code-termux.fish | fish
#   curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/install-claude-code-termux.fish | fish
#

echo "===== Termux Claude Code Installer ====="
echo

if not test -d "/data/data/com.termux/files/usr"; and test -z "$TERMUX_VERSION"
    echo "Warning: This script is intended for Android Termux."
end

echo "Updating Termux packages..."
pkg update -y

echo "Installing Node.js and Git..."
pkg install -y nodejs git

echo "Node version: "(node -v 2>/dev/null; or echo 'not found')
echo "NPM version:  "(npm -v 2>/dev/null; or echo 'not found')

echo
echo "Installing compatible Claude Code CLI (v2.1.47)..."
npm install -g @anthropic-ai/claude-code@2.1.47

echo
echo "Verifying installation..."
set -l NPM_ROOT (npm root -g)
if test -f "$NPM_ROOT/@anthropic-ai/claude-code/cli.js"
    echo "[OK] cli.js found in $NPM_ROOT/@anthropic-ai/claude-code"
else
    echo "[WARN] cli.js not located at expected path."
end

if command -v claude >/dev/null 2>&1
    echo "[OK] Claude binary is accessible in PATH."
    echo "Claude version: "(claude --version 2>/dev/null)
else
    echo "[INFO] Running via direct node invocation:"
    node "$NPM_ROOT/@anthropic-ai/claude-code/cli.js" --version
end

echo
echo "========================================"
echo "Installation complete."
echo "Run 'claude' to log in and start your session."
echo "========================================"
