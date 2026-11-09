#!/usr/bin/env bash
#
# install-claude-code-termux.sh: Installs compatible Claude Code CLI (v2.1.47) in Android Termux.
#
# Usage:
#   ./install-claude-code-termux.sh
#   curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/install-claude-code-termux.sh | bash
#

set -euo pipefail

echo "===== Termux Claude Code Installer ====="
echo

# Verify Termux userland
if [[ ! -d "/data/data/com.termux/files/usr" ]] && [[ -z "${TERMUX_VERSION:-}" ]]; then
    echo "Warning: This script is intended for Android Termux."
fi

echo "Updating Termux packages..."
pkg update -y

echo "Installing Node.js and Git..."
pkg install -y nodejs git

echo "Node version: $(node -v 2>/dev/null || echo 'not found')"
echo "NPM version:  $(npm -v 2>/dev/null || echo 'not found')"

echo
echo "Installing compatible Claude Code CLI (v2.1.47)..."
npm install -g @anthropic-ai/claude-code@2.1.47

echo
echo "Verifying installation..."
NPM_ROOT="$(npm root -g)"
if [[ -f "$NPM_ROOT/@anthropic-ai/claude-code/cli.js" ]]; then
    echo "[OK] cli.js found in $NPM_ROOT/@anthropic-ai/claude-code"
else
    echo "[WARN] cli.js not located at expected path."
fi

if command -v claude >/dev/null 2>&1; then
    echo "[OK] Claude binary is accessible in PATH."
    echo "Claude version: $(claude --version 2>/dev/null || true)"
else
    echo "[INFO] Running via direct node invocation:"
    node "$NPM_ROOT/@anthropic-ai/claude-code/cli.js" --version || true
fi

echo
echo "========================================"
echo "Installation complete."
echo "Run 'claude' to log in and start your session."
echo "========================================"
