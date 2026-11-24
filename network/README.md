# Network Fixes

Wi-Fi, mobile hotspot, connectivity, network adapter, bandwidth optimization, and protocol troubleshooting.

## Wi-Fi & Wireless Interfaces

- [QCA9377 Automatic Wi-Fi Fix](wifi/qca9377-auto-fix.md): Automatic driver inspection and power save disabling for Arch Linux.
- [QCA9377 Hotspot Disconnect Fix](wifi/qca9377-hotspot-disconnect-fix.md): Hotspot drop mitigation, firmware crash isolation, and power saving configuration.

## Bandwidth Optimization & Traffic Control

- [Linux & Android Internet Data Optimization](linux-android-internet-usage-optimization.md): 12-hour continuous streaming on a 1 GB quota, cache clamping, traffic shaping, and hotspot background control.
- [Internet Data Drain Reduction](internet-data-drain-reduction.md): NetworkManager metered profiles, traffic accounting, per-transfer rate limits, pacman download controls, Git and Docker cache guidance, and Android per-app restrictions.

## Quick Execution One-Liners

| Target Fix / Optimization | Direct One-Line curl Command |
| --- | --- |
| QCA9377 Wi-Fi Powersave (Apply) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- apply` |
| QCA9377 Wi-Fi Powersave (Apply) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- apply` |
| QCA9377 Wi-Fi Powersave (Status) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/wifi/scripts/qca9377-powersave-fix.sh \| bash -s -- status` |
| QCA9377 Wi-Fi Powersave (Status) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/wifi/scripts/qca9377-powersave-fix.sh \| bash -s -- status` |
| QCA9377 Wi-Fi Powersave (Revert) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- revert` |
| QCA9377 Wi-Fi Powersave (Revert) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- revert` |
| Hotspot Background Saver (Apply) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- apply` |
| Hotspot Background Saver (Apply) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- apply` |
| Hotspot Background Saver (Status) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- status` |
| Hotspot Background Saver (Status) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- status` |
| Hotspot Background Saver (Revert) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- revert` |
| Hotspot Background Saver (Revert) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- revert` |
