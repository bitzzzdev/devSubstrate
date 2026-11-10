# DevSubstrate Smart Curl Scripts

This branch contains two curl launchers. They combine the Android, Linux, and
network fixes from the full repository into numbered commands.

The launchers fetch the implementation scripts from the `dev` branch. Set
`DEVSUBSTRATE_REF` to a commit or another branch when reproducible pinning is
needed.

## Android

Run the menu:

```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/androidCurlScripts.sh | bash
```

Run a selection directly:

```bash
# 1: device information
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/androidCurlScripts.sh | bash -s -- 1

# 2: reduce shopping traffic
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/androidCurlScripts.sh | bash -s -- 2 shopping

# 3: revert shopping restrictions
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/androidCurlScripts.sh | bash -s -- 3 shopping
```

Android option targets:

| Option | Target | Direct argument |
| --- | --- | --- |
| 1 | Device information and storage status | `1` |
| 2 | Reduce shopping or hotspot traffic | `2 shopping`, `2 hotspot`, `2 all` |
| 3 | Revert shopping, hotspot, or Google Cloud changes | `3 shopping`, `3 hotspot`, `3 gcloud` |
| 4 | Inspect or trim storage | `4 status`, `4 trim` |
| 5 | Install Claude Code or configure Google Cloud in Termux | `5 claude`, `5 gcloud` |

The Android launcher uses ADB when an authorized device is connected. Without
ADB it uses the Termux implementation.

## Linux

Run the menu:

```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/linuxCurlScripts.sh | bash
```

Run a selection directly:

```bash
# 1: pre-reboot device and boot information
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/linuxCurlScripts.sh | bash -s -- 1

# 2: reduce hotspot background traffic
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/linuxCurlScripts.sh | bash -s -- 2 hotspot

# 3: revert a Wi-Fi power setting
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/smartCurlScripts/linuxCurlScripts.sh | bash -s -- 3 wifi
```

Linux option targets:

| Option | Target | Direct argument |
| --- | --- | --- |
| 1 | Pre-reboot device and boot health check | `1` |
| 2 | Reduce hotspot or Wi-Fi network drainage | `2 hotspot`, `2 wifi` |
| 3 | Revert a named change | `3 hotspot`, `3 wifi`, `3 uki`, `3 vlc`, `3 ssh` |
| 4 | Apply a named system fix | `4 uki`, `4 vlc`, `4 ssh` |
| 5 | Create, inspect, or remove a sudo user | `5 create <username>` |
| 6 | Install Legacy Launcher | `6` |

Some Linux operations require `sudo`, an Arch Linux system, or an authorized
ADB device. Read the underlying guide before running a system-changing option.

## Full non-curl scripts

The implementation scripts, Fish versions, guides, research papers, and
project history remain in the full `dev` branch:

https://github.com/bitzzdev/devSubstrate/tree/dev

Inspect a fetched script before running it. These launchers execute remote
shell code by design.

## License

MIT. See [LICENSE](LICENSE).
