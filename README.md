# DevSubstrate Smart Curl Scripts

This branch publishes two Bash launchers for the Android, Termux, Arch Linux,
and network maintenance scripts in the `dev` branch.

The launchers fetch implementation scripts from GitLab by default. Set
`DEVSUBSTRATE_REMOTE=github` to use the GitHub mirror, and set
`DEVSUBSTRATE_REF` to pin a branch or commit. The launcher downloads each
script to a temporary file, checks it with `bash -n`, and executes it only
after a successful download and syntax check. When invoked through sudo, they preserve the invoking user's home directory for downloaded scripts that manage user files.

When a launcher must run as root, place environment assignments after
`sudo`, for example `sudo env DEVSUBSTRATE_REMOTE=github bash`. Do not
place them before `sudo`, because sudo may remove them from the command
environment.

## Android and Termux

Run the interactive menu:

```bash
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/androidCurlScripts.sh | bash
```

Run an option directly:

```bash
# Device and storage status
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/androidCurlScripts.sh | bash -s -- 1

# Restrict shopping app background activity and hotspot background traffic
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/androidCurlScripts.sh | bash -s -- 2 all

# Restore shopping and hotspot restrictions
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/androidCurlScripts.sh | bash -s -- 3 shopping
```

| Option | Target | Direct argument |
| --- | --- | --- |
| 1 | Device information and storage status | `1` |
| 2 | Reduce shopping or hotspot background activity | `2 shopping`, `2 hotspot`, `2 all` |
| 3 | Revert shopping, hotspot, or Google Cloud changes | `3 shopping`, `3 hotspot`, `3 gcloud` |
| 4 | Inspect or trim storage | `4 status`, `4 trim` |
| 5 | Install Claude Code or configure Google Cloud in Termux | `5 claude`, `5 gcloud` |

Option 2 defaults to `all`. It continues to the second target if the first
target fails, then returns a non-zero status if either operation failed. The
launcher uses ADB when an authorized device is connected. Without ADB it uses
the Termux implementation.

## Linux and Arch Linux

Run the interactive menu:

```bash
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | sudo bash
```

Run a selection directly:

```bash
# Device and boot health information
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | bash -s -- 1

# Mark the active NetworkManager Wi-Fi profile as metered
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | sudo bash -s -- 2 wifi

# Restrict background traffic on an Android phone connected through ADB
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | sudo bash -s -- 2 hotspot

# Restore automatic metered-state detection for the active Wi-Fi profile
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | sudo bash -s -- 3 wifi

# Apply or revert the device-specific QCA9377 power-save setting
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | sudo bash -s -- 4 qca9377
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | sudo bash -s -- 3 qca9377
```

| Option | Target | Direct argument |
| --- | --- | --- |
| 1 | Pre-reboot device and boot health check | `1` |
| 2 | Reduce network data drainage | `2 hotspot`, `2 wifi` |
| 3 | Revert a named change | `3 hotspot`, `3 wifi`, `3 qca9377`, `3 uki`, `3 vlc`, `3 ssh` |
| 4 | Apply a system fix | `4 qca9377`, `4 uki`, `4 vlc`, `4 ssh` |
| 5 | Create, inspect, or remove a sudo user | `5 create <username>`, `5 status <username>`, `5 remove <username>` |
| 6 | Install Legacy Launcher | `6` |

The `wifi` data-reduction target marks the active NetworkManager Wi-Fi profile
as metered. Compatible applications may defer or reduce background downloads.
It does not block all traffic or impose a hard quota. The separate
`qca9377` target controls power saving for Qualcomm QCA9377 adapters and is
not a data-metering feature.

The `hotspot` target requires an authorized ADB device and applies Android
background restrictions. It does not configure Linux Wi-Fi.

## Remote selection

GitLab is the default source. To fetch implementation scripts from GitHub,
set the variable in the command executed by sudo:

```bash
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/smartCurlScripts/linuxCurlScripts.sh | sudo env DEVSUBSTRATE_REMOTE=github bash -s -- 2 wifi
```

To pin the implementation branch or commit, pass `DEVSUBSTRATE_REF` the same
way, for example `sudo env DEVSUBSTRATE_REF=dev bash`.

## Full repository

The implementation scripts, Fish variants, guides, research papers, and
project history remain in the full repository:

- https://gitlab.com/bitzzdev/devSubstrate/tree/dev
- https://github.com/bitzzdev/devSubstrate/tree/dev

The launchers execute remote shell code. Inspect the launcher and the target
implementation before running unfamiliar operations.

## License

MIT. See [LICENSE](LICENSE).
