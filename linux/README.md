# Linux Fixes

Linux distribution, desktop, boot, package, application, and maintenance guides with verified execution scripts and curl one-liners.

## Arch Linux

- [UKI boot parameters and QCA9377 Wi-Fi fix](arch/uki-qca9377-wifi-fix.md): Kernel cmdline overrides and UKI regeneration.
- [VLC H.264 codec fix](arch/vlc-h264-codec-fix.md): Missing FFmpeg plugin package installation.
- [Create a sudo user](arch/create-sudo-user.md): Interactive user creation and wheel group delegation.
- [Pre-reboot boot health check](arch/pre-reboot-health-check.md): Kernel, UKI, and `/boot` mount verification.

## Remote & Cloud Shell

- [Cloud Shell SSH X11 Clipboard Fix](ssh/gcloud-ssh-x11-clipboard-fix.md): Persistent X11 forwarding and alias setup.

## Desktop Applications

- [Legacy Launcher Installation Guide](scripts/install-legacy-launcher.md): Desktop entry and launcher deployment.

## Quick Execution One-Liners

| Target Fix | Direct One-Line curl Command |
| --- | --- |
| UKI Wi-Fi Fix (Apply) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/uki-qca9377-fix.sh \| sudo bash -s -- apply` |
| UKI Wi-Fi Fix (Apply) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/uki-qca9377-fix.sh \| sudo bash -s -- apply` |
| VLC H.264 Plugin (Apply) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh \| sudo bash -s -- apply` |
| VLC H.264 Plugin (Apply) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh \| sudo bash -s -- apply` |
| Sudo User Setup | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/manage-sudo-user.sh \| sudo bash -s -- create <user>` |
| Sudo User Setup (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/manage-sudo-user.sh \| sudo bash -s -- create <user>` |
| Pre-Reboot Health Check | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/pre-reboot-health-check.sh \| bash` |
| Pre-Reboot Health Check (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/pre-reboot-health-check.sh \| bash` |
| SSH X11 Clipboard (Apply) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/ssh/scripts/configure-ssh-x11-forwarding.sh \| bash -s -- apply` |
| SSH X11 Clipboard (Apply) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/ssh/scripts/configure-ssh-x11-forwarding.sh \| bash -s -- apply` |
| Legacy Launcher Install | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/scripts/install-legacy-launcher.sh \| bash` |
| Legacy Launcher Install (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/scripts/install-legacy-launcher.sh \| bash` |
