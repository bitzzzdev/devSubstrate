# Reduce Internet Data Usage on Linux and Android

This guide focuses on reducing avoidable background traffic, preventing large
downloads from consuming an entire mobile quota, and identifying which process
is using the connection. It complements the existing
[low-bandwidth streaming guide](linux-android-internet-usage-optimization.md)
and the [hotspot background traffic controls](scripts/hotspot-background-traffic-control.sh).

A key distinction matters:

- **Data reduction** lowers the number of bytes transferred. Examples include
  disabling unnecessary sync, avoiding repeated downloads, choosing lower
  media bitrates, and reusing package caches.
- **Rate limiting** slows a transfer but normally does not reduce its total
  byte count. Use it to keep one download from monopolizing a weak connection.
- **Metered-network signaling** tells compatible applications that the
  connection has a data cost. It does not act as a firewall or a hard quota.

## 1. Find what is consuming data before changing anything

Do not guess which service is responsible. Measure traffic first.

### Arch Linux package installation

Install these tools when connected to an unmetered network. `vnstat` records
per-interface totals over time. `nethogs` shows current per-process traffic.

```fish
sudo pacman -S --needed vnstat nethogs
sudo systemctl enable --now vnstat
vnstat --days
vnstat --months
vnstat --live
sudo nethogs
```

```bash
sudo pacman -S --needed vnstat nethogs
sudo systemctl enable --now vnstat
vnstat --days
vnstat --months
vnstat --live
sudo nethogs
```

For a short live rate sample without installing a monitor:

```fish
ip -s link
ip route get 1.1.1.1
```

```bash
ip -s link
ip route get 1.1.1.1
```

The interface counters are cumulative since the interface was brought up.
They are not a monthly quota meter. Use `vnstat` for history and compare it
with the carrier's own usage counter because the carrier may count tethered
devices, protocol overhead, and billing sessions differently.

## 2. Mark the current Wi-Fi connection as metered

On systems using NetworkManager, set the active connection profile to
metered. Compatible desktop applications can then avoid or defer large
background downloads. NetworkManager applies a changed metered property to
an already active profile immediately.

### Fish

```fish
set active (nmcli -g NAME connection show --active | head -n 1)

if test -n "$active"
    nmcli connection modify "$active" connection.metered yes
    nmcli -f connection.id,connection.metered connection show "$active"
else
    echo "No active NetworkManager connection found."
end
```

### Bash

```bash
active="$(nmcli -g NAME connection show --active | head -n 1)"

if [[ -n "$active" ]]; then
    nmcli connection modify "$active" connection.metered yes
    nmcli -f connection.id,connection.metered connection show "$active"
else
    echo "No active NetworkManager connection found."
fi
```

To restore automatic detection for that profile, replace `yes` with
`unknown`:

### Fish

```fish
set active (nmcli -g NAME connection show --active | head -n 1)
if test -n "$active"
    nmcli connection modify "$active" connection.metered unknown
end
```

### Bash

```bash
active="$(nmcli -g NAME connection show --active | head -n 1)"
if [[ -n "$active" ]]; then
    nmcli connection modify "$active" connection.metered unknown
fi
```

This changes only the selected NetworkManager profile. Repeat it for another
profile when you connect through a different hotspot. If you use iwd directly,
systemd-networkd, or another network manager, do not run these commands.

## 3. Limit individual downloads

Use a per-command rate cap for large downloads over a mobile hotspot. The
examples below cap each transfer at 250 KiB/s. Change the value to suit the
available quota and connection quality.

### Fish

```fish
curl --fail --location --limit-rate 250K --output archive.tar.zst "https://example.org/archive.tar.zst"
wget --continue --limit-rate=250k "https://example.org/archive.tar.zst"
```

### Bash

```bash
curl --fail --location --limit-rate 250K --output archive.tar.zst "https://example.org/archive.tar.zst"
wget --continue --limit-rate=250k "https://example.org/archive.tar.zst"
```

The rate cap controls transfer speed, not the final file size. A 2 GB file
still transfers approximately 2 GB. Check the expected size before starting
a large download. The `curl --limit-rate` and GNU Wget
`--limit-rate` options are documented by their upstream projects.

## 4. Reduce Arch package-manager download bursts

Pacman supports an external downloader through `XferCommand`. Its URL and
output placeholders are substituted by pacman. A curl command can therefore
resume partial package downloads and apply a transfer-rate ceiling.

Open `/etc/pacman.conf`:

```bash
sudoedit /etc/pacman.conf
```

Under the existing `[options]` section, set:

```ini
ParallelDownloads = 1
XferCommand = /usr/bin/curl --fail --location --continue-at - --output %o --limit-rate 300K %u
```

Keep only one active `XferCommand` line. Confirm that `/usr/bin/curl` exists
before saving. Pacman normally downloads sequentially when
`ParallelDownloads` is unset; setting it to `1` makes that choice explicit.

**Important:** `ParallelDownloads = 1` reduces concurrent transfer bursts,
not the total bytes needed for an upgrade. The `XferCommand` rate cap slows
each package transfer, but it also does not shrink package files. Review the
transaction before confirming an upgrade:

```fish
sudo pacman -Syu
```

```bash
sudo pacman -Syu
```

Pacman will show the package transaction and download size before proceeding.
Do not skip security updates indefinitely to save data. Prefer scheduling
large upgrades for an unmetered connection.

Do not clear `/var/cache/pacman/pkg` as a data-saving measure. Cached package
archives can prevent a later reinstall or rollback from downloading the same
package again. Cache cleanup saves disk space, not mobile data.

## 5. Avoid unnecessary repository and development downloads

Use smaller Git fetches when the full history and every file are not needed.

### Fish

```fish
git clone --depth 1 --single-branch --filter=blob:none https://gitlab.com/group/project.git
```

### Bash

```bash
git clone --depth 1 --single-branch --filter=blob:none https://gitlab.com/group/project.git
```

A shallow, blob-filtered clone is useful for inspection and build jobs that
need only the current revision. It is not a drop-in replacement for a full
development clone: later history operations, checkout of older revisions,
submodules, and Git LFS content can trigger additional transfers.

Keep local package caches where practical. Repeatedly deleting npm, pip,
Cargo, Gradle, Docker, or pacman caches usually increases future network
usage because dependencies and layers must be downloaded again.

For Docker, inspect image storage before pulling or rebuilding:

```fish
docker system df
docker image ls
```

```bash
docker system df
docker image ls
```

Docker downloads multiple image layers concurrently by default. Its daemon
supports lowering `max-concurrent-downloads` for low-bandwidth links. This
reduces simultaneous network pressure, not the total image size. Change the
daemon setting only if Docker is installed and used on this machine, and
restart the daemon only when you are ready for running containers to be
affected. Do not run `docker system prune` just to save data; deleting cached
images can force them to be downloaded again.

## 6. Find automatic jobs instead of disabling services blindly

List system and user timers before changing update or synchronization behavior:

### Fish

```fish
systemctl list-timers --all
systemctl --user list-timers --all
systemctl list-units --type=service --state=running
```

### Bash

```bash
systemctl list-timers --all
systemctl --user list-timers --all
systemctl list-units --type=service --state=running
```

Look for timers or services belonging to software you actually use, such as
desktop software centers, cloud-drive clients, game launchers, container
updates, or browser background updates. Change the schedule or disable
automatic downloads in that application's settings. Do not disable an
unknown system timer or a security update service based only on its name.

Arch Linux does not require a permanently running automatic package updater.
Run system upgrades deliberately when the connection and quota allow it.

## 7. Android and Termux connected through a hotspot

Android Data Saver is designed to restrict background metered-data use.
The Android documentation also exposes ADB commands for inspecting network
policy and testing Data Saver behavior. However, global Data Saver and
hotspot/tethering behavior can vary by device and OEM build.

For this repository's hotspot-preserving workflow, prefer the scoped per-app
script instead of changing global policy:

```bash
adb devices
bash android/scripts/app-data-saver.sh status
bash android/scripts/app-data-saver.sh apply
```

To revert only the UIDs recorded by that script:

```bash
bash android/scripts/app-data-saver.sh revert
```

The script requires an authorized ADB connection. Read
[Android per-app data saver](../android/app-data-saver.md) before applying it.
For the separate hotspot background profile, use
[hotspot-background-traffic-control](scripts/hotspot-background-traffic-control.sh)
and its `apply`, `status`, and `revert` actions. Do not apply both profiles
without reading their different policy scopes.

## 8. Settings that usually do not save meaningful data

- **DNS changes:** DNS caching reduces repeated lookups, but DNS traffic is
  usually tiny compared with video, software updates, cloud sync, and large
  downloads. systemd-resolved enables its cache by default. Changing DNS
  providers is not a substitute for controlling application downloads.
- **Slower downloads:** A rate limit controls bandwidth use per second. It
  does not reduce the amount of data transferred.
- **Deleting caches:** This can increase future data use by forcing packages,
  dependencies, and image layers to be fetched again.
- **Disabling IPv6 or changing MTU blindly:** These changes do not provide a
  general data-saving benefit and can break connectivity or increase retries.
- **Blocking all background traffic:** This can break messaging, notifications,
  authentication, backups, sync, and hotspot clients. Restrict specific apps
  only after identifying them.

## 9. A practical low-data routine

1. Check the carrier's remaining quota and the host's `vnstat` totals.
2. Use `nethogs` to identify the process responsible for unexpected traffic.
3. Mark the active NetworkManager profile as metered.
4. Pause non-essential cloud sync, game downloads, and application updates in
   their own settings.
5. Keep package and dependency caches. Schedule large upgrades for Wi-Fi with
   no quota limit.
6. Rate-limit unavoidable large downloads.
7. Check usage again after 15 to 30 minutes and compare the before/after
   counters. Do not claim a percentage saving without measured data.

## References

- [NetworkManager connection settings](https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nm-settings-nmcli.html)
- [NetworkManager nmcli manual](https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nmcli.html)
- [Arch pacman.conf manual](https://man.archlinux.org/man/pacman.conf.5.en)
- [ArchWiki: Pacman tips and tricks](https://wiki.archlinux.org/title/Pacman/Tips_and_tricks)
- [curl manual: --limit-rate](https://curl.se/docs/manpage.html)
- [GNU Wget download options](https://www.gnu.org/software/wget/manual/html_node/Download-Options.html)
- [systemd-resolved configuration](https://www.freedesktop.org/software/systemd/man/latest/resolved.conf.html)
- [Android: Optimize network data usage](https://developer.android.com/develop/connectivity/network-ops/data-saver)
- [Android Open Source Project: Data Saver](https://source.android.com/docs/core/data/data-saver)
- [Docker: docker image pull](https://docs.docker.com/reference/cli/docker/image/pull/)
- [vnStat real-time monitoring](https://github.com/vergoh/vnstat/wiki/Usage-%23-Real-time-monitoring-modes)
