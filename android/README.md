# Android Fixes

Android device diagnostics, ADB workflows, app troubleshooting, storage cleanup, battery and performance investigations, and Termux mobile tooling.

## Device Optimization & ADB Procedures

- [Cellular Traffic & Notification Saver](cellular-data-notification-saver.md): Granular background traffic and notification control over ADB.
- [AppOps Permission Monitor Troubleshooting](appops-permission-monitor.md): Realme UI and ColorOS guidance for ADB AppOps permission denials.
- [Storage Space Recovery Guide](storage-optimization.md): Partition diagnostics and non-destructive package cache trimming.
- [Realme C11 RMX3231 Performance and Battery Log](realme-c11-rmx3231-optimization.md): Hardware baseline, memory analysis, and process investigations.

## Termux On-Device Execution

- [Termux Mobile Fix Hub](termux-scripts/README.md): Self-contained on-device scripts with execution audits and unprivileged fallbacks.
- [Claude Code CLI Workaround on Termux](termux/claude-code-cli-workaround.md): Installation procedure and verification for compatible Claude Code CLI.
- [Google Cloud CLI on Termux](termux/gcloud-cli-termux-workaround.md): Platform-specific SDK setup, Python paths, and Cloud Shell aliases.

## Quick Execution One-Liners

| Target Fix / Tool | Direct One-Line curl Command |
| --- | --- |
| Shopping Traffic (Pause via ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- pause` |
| Shopping Traffic (Pause via ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- pause` |
| Storage Audit (via ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/audit-android-storage.sh \| bash -s -- status` |
| Storage Audit (via ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/audit-android-storage.sh \| bash -s -- status` |
| Cache Trim (via ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/audit-android-storage.sh \| bash -s -- trim` |
| Cache Trim (via ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/audit-android-storage.sh \| bash -s -- trim` |
| Termux Shopping Traffic Pause | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux-scripts/termux-manage-shopping-traffic.sh \| bash -s -- pause` |
| Termux Shopping Traffic Pause (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux-scripts/termux-manage-shopping-traffic.sh \| bash -s -- pause` |
| Termux Hotspot Background Saver | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux-scripts/termux-hotspot-traffic-control.sh \| bash -s -- apply` |
| Termux Hotspot Background Saver (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux-scripts/termux-hotspot-traffic-control.sh \| bash -s -- apply` |
| Termux Storage Audit & Trim | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux-scripts/termux-audit-storage.sh \| bash -s -- status` |
| Termux Storage Audit & Trim (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux-scripts/termux-audit-storage.sh \| bash -s -- status` |
| Termux Claude Code Install | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/install-claude-code-termux.sh \| bash` |
| Termux Claude Code Install (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/install-claude-code-termux.sh \| bash` |
| Termux Google Cloud SDK Setup | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.sh \| bash -s -- apply` |
| Termux Google Cloud SDK Setup (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/setup-gcloud-termux.sh \| bash -s -- apply` |
