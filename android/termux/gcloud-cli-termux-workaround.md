# Google Cloud CLI and Cloud Shell on Android (Termux)

Tested with: Google Cloud SDK 592.0.0+ on Termux (aarch64 / Android)

The official Google Cloud SDK installer and component updater fail on Android Termux with component errors (`[gcloud, gcloud-crc32c] are unknown`) and Python path issues. This runbook documents the root causes, architecture bypasses, headless authentication, session authorization, and shell aliases for Termux.

---

## Root Cause Analysis

### 1. Component Registry Incompatibility
Google distributes platform-specific compiled C extensions (such as `gcloud-crc32c`) through its component manager. Because Google does not publish builds compiled against the Android Bionic C runtime, running `gcloud components update` or installing standard component bundles fails with:

```text
ERROR: (gcloud.components.update) The following components are unknown [gcloud, gcloud-crc32c]
```

**Resolution**: The core Google Cloud CLI is pure Python. Bypassing component management via `--override-components` or skipping component updates allows the full CLI to run without binary mismatch errors.

### 2. Python Environment Paths
Termux uses a non-standard filesystem prefix (`/data/data/com.termux/files/usr/`). Standard shebangs and paths like `/usr/bin/python` do not resolve. If `CLOUDSDK_PYTHON` is not set explicitly, `gcloud` fails to locate the Python runtime or selects an incompatible binary.

**Resolution**: Explicitly point `CLOUDSDK_PYTHON` to `/data/data/com.termux/files/usr/bin/python` in shell profile scripts.

---

## Automated Setup (One-Line curl Commands)

Install prerequisites, download Google Cloud SDK, and configure environment exports and aliases automatically:

### Apply Setup
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.sh | bash -s -- apply
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/setup-gcloud-termux.sh | bash -s -- apply
```

### Check Status
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.sh | bash -s -- status
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/setup-gcloud-termux.sh | bash -s -- status
```

### Revert Configuration
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.sh | bash -s -- revert
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/setup-gcloud-termux.sh | bash -s -- revert
```

Fish shell alternative:
```fish
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.fish | fish -s -- apply
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/setup-gcloud-termux.fish | fish -s -- apply
```

---

## Manual Installation Walkthrough

### 1. Install Prerequisites

Update packages and install Python, curl, and OpenSSH:

```bash
pkg update -y
pkg install -y python curl openssh
```

### 2. Download and Extract the SDK

Download the Google Cloud SDK archive directly to your home directory:

```bash
curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
```

If the installer prompts for components, bypass the check:

```bash
~/google-cloud-sdk/install.sh --override-components
```

---

## Shell Configuration and Aliases

Add the following environment settings, aliases, and helper function to `~/.bashrc`:

```bash
# Python runtime and PATH
export CLOUDSDK_PYTHON="/data/data/com.termux/files/usr/bin/python"
export PATH="$HOME/google-cloud-sdk/bin:$PATH"

if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then
    source "$HOME/google-cloud-sdk/path.bash.inc"
fi

if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then
    source "$HOME/google-cloud-sdk/completion.bash.inc"
fi

# Connect to Google Cloud Shell with propagated OAuth credentials
alias gcs='gcloud cloud-shell ssh --authorize-session'
alias cloudshell='gcloud cloud-shell ssh --authorize-session'

# Multi-account management
alias glogin='gcloud auth login --no-browser'
alias gaccounts='gcloud auth list'
alias gswitch='gcloud config set account'

# Alias usage helper
ghelp() {
    cat << 'EOF'
==================================================
        Google Cloud Termux Helper Aliases
==================================================

1. Connect to Cloud Shell:
   gcs             SSH into Google Cloud Shell with session auth
   cloudshell      Same as 'gcs'

2. Multi-Account Management:
   glogin          Log in to a new/different Google account
   gaccounts       List all authorized accounts on this device
   gswitch <email> Switch active account
                   Example: gswitch user@gmail.com

3. Useful gcloud Built-in Commands:
   gcloud projects list              List accessible projects
   gcloud config set project <id>    Set default GCP project
   gcloud info                       Display CLI & Python diagnostics
==================================================
EOF
}
alias gcloud-help='ghelp'
```

Reload the shell to activate the configuration:

```bash
source ~/.bashrc
```

---

## Authentication and Verification

### 1. Authenticate Without a Local Browser

Because Termux has no desktop web browser, use console authentication:

```bash
glogin
```

1. Copy the authentication URL from Termux and open it in your mobile web browser.
2. Sign in and grant access to the desired Google account.
3. Copy the resulting verification code, paste it back into Termux, and press Enter.

### 2. Verify Active Configuration

Check the installed version and account status:

```bash
gcloud --version
gaccounts
```

### 3. Connect to Google Cloud Shell

Launch an interactive SSH session into your remote Cloud Shell container with credentials pre-authorized:

```bash
gcs
```
