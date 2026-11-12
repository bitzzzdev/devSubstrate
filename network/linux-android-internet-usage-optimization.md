# Low-Bandwidth Video Streaming: 12 Hours on a 1 GB Data Quota

A technical guide and configuration reference for sustaining continuous video playback across a twelve-hour window on a strict 1-gigabyte (GB) cellular data allowance without exhausting bandwidth or terminating mobile hotspot routing.

---

## 1. Mathematical Bandwidth Budget

A 12-hour continuous streaming session consists of 43,200 seconds ($12 \times 3,600\text{ seconds}$). Cellular carriers bill data usage using the International System of Units (SI decimal: $1\text{ GB} = 10^9\text{ bytes}$), while operating system runtimes frequently calculate values using binary standards (IEC binary: $1\text{ GiB} = 2^{30}\text{ bytes}$).

The bit capacity ($Q_{\text{bits}}$) and gross continuous bitrate ceiling ($R_{\text{gross}}$) are determined by:

$$Q_{\text{bits}} = Q_{\text{bytes}} \times 8$$

$$R_{\text{gross}} = \frac{Q_{\text{bits}}}{T}$$

Under an SI decimal quota ($10^9$ bytes), the gross bandwidth budget is 185.19 kbps (23.15 KB/s). Under an IEC binary quota ($2^{30}$ bytes), the gross budget is 198.84 kbps (24.86 KB/s).

Accounting for network encapsulation (IPv4/IPv6, TCP/UDP, TLS 1.3, HTTP/2 or HTTP/3 QUIC), DASH/HLS playlist manifest polling, container overhead, and cellular radio retransmissions (estimated at 5% to 10%), the net bandwidth budget available for media payloads is:

| Quota Metric Standard | Gross Quota (Bytes) | Gross Bitrate | Net Bitrate (5% Overhead) | Net Bitrate (8% Overhead) | Net Bitrate (10% Overhead) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| SI Decimal (1 GB) | 1,000,000,000 | 185.19 kbps | 175.93 kbps | 170.37 kbps | 166.67 kbps |
| IEC Binary (1 GiB) | 1,073,741,824 | 198.84 kbps | 188.90 kbps | 182.93 kbps | 178.96 kbps |

Under standard carrier billing with an 8% transport penalty, the continuous media stream must not exceed **170.37 kbps** (21.30 KB/s).

---

## 2. Codec and Resolution Analysis

### 480p Feasibility
A 480p frame ($854 \times 480$) contains 409,920 pixels. At standard framerates (24-30 fps):
* **H.264 / AVC (itag 135):** Requires 334 to 356 kbps for video alone.
* **VP9 (itag 244):** Requires 382 to 410 kbps for video alone.
* **AV1 (itag 397):** Requires approximately 298.5 kbps for video alone.

At 298.5 kbps, 480p AV1 exhausts a 1 GB plan in roughly 7.4 hours without accounting for audio or packet overhead. Sustained 480p playback is not mathematically possible within a 12-hour, 1 GB budget.

### 360p Feasibility
A 360p frame ($640 \times 360$) contains 230,400 pixels (a 43.75% reduction in pixel count compared to 480p):
* **H.264 / AVC (itag 134):** Video operates at 198 to 212 kbps, exceeding the 170.37 kbps budget before audio multiplexing.
* **VP9 (itag 243):** Video operates at 216.5 to 253 kbps.
* **AV1 (itag 396):** Video operates at **120 to 140 kbps**, fitting comfortably inside the 170.37 kbps ceiling alongside an audio stream.
* **AV1 (itag 395 - 240p):** Operates at ~86.2 kbps, serving as an adaptive fallback during complex scenes.

### Audio Optimization: Opus vs. AAC
Standard streaming delivers 128 kbps AAC audio (itag 140), which consumes 75% of the allowable 170.37 kbps budget. To achieve 12 hours of playback, you must isolate low-bitrate **Opus** audio:
* **Opus Low (itag 249):** Operates at 48 to 52 kbps, reducing audio data consumption by 60% compared to AAC while maintaining intelligible speech and acceptable fidelity.
* **Opus Ultra-Low (itag 599/600):** Operates at ~34 kbps for spoken content.

| Format Code (itag) | Container / Codecs | Resolution | Video Bitrate | Audio Bitrate | Total Bitrate | Hourly Consumption | 1 GB Lifetime |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 18 | MP4 (H.264 + AAC) | 360p (Muxed) | ~390 kbps | ~96 kbps | ~486 kbps | 218.7 MB/hr | 4.57 hours |
| 135 + 140 | MP4 (H.264 + AAC) | 480p (DASH) | ~356 kbps | ~128 kbps | ~484 kbps | 217.8 MB/hr | 4.59 hours |
| 244 + 251 | WebM (VP9 + Opus) | 480p (DASH) | ~382 kbps | ~128 kbps | ~510 kbps | 229.5 MB/hr | 4.35 hours |
| 397 + 249 | MP4/WebM (AV1 + Opus) | 480p (DASH) | ~298.5 kbps | ~52 kbps | ~350.5 kbps | 157.7 MB/hr | 6.34 hours |
| 134 + 140 | MP4 (H.264 + AAC) | 360p (DASH) | ~212 kbps | ~128 kbps | ~340 kbps | 153.0 MB/hr | 6.53 hours |
| 243 + 249 | WebM (VP9 + Opus) | 360p (DASH) | ~216.5 kbps | ~52 kbps | ~268.5 kbps | 120.8 MB/hr | 8.28 hours |
| 396 + 249 | MP4/WebM (AV1 + Opus) | 360p (DASH) | ~120-140 kbps | ~52 kbps | ~172-192 kbps | 77.4-86.4 MB/hr | 11.6-12.9 hours |
| 395 + 249 | MP4/WebM (AV1 + Opus) | 240p (DASH) | ~86.2 kbps | ~52 kbps | ~138.2 kbps | 62.2 MB/hr | 16.1 hours |

---

## 3. Official Platform Settings vs. Actual Data Burn

Native platform settings and Data Saver modes do not limit bitrates enough to survive 12 hours on 1 GB:

* **YouTube Data Saver Mode:** Drops video to 360p or 480p, but serves legacy muxed streams (itag 18) or pairs video with 128 kbps AAC. Consumption ranges from 250 to 400 MB per hour (depleting 1 GB in 2.5 to 4 hours). YouTube's documentation recommends 0.7 Mbps (700 kbps) sustained speed for 360p.
* **Netflix Mobile "Save Data":** Delivers ~6 hours of streaming per GB (~166.7 MB per hour). Browser "Low" quality uses up to 300 MB per hour (lasting ~3.3 hours); "Medium" (SD) uses up to 700 MB per hour (lasting ~1.4 hours).
* **Twitch Mobile Transcodes:** Live streaming introduces real-time encoding overhead. Twitch 360p streams run at 600 to 800 kbps (270 to 360 MB per hour, lasting 2.8 to 3.7 hours). Twitch 480p streams run at 900 to 1,200 kbps (lasting under 2.5 hours).

| Platform | Setting / Profile | Resolution | Realized Bitrate | Hourly Data Burn | 1 GB Lifetime |
| :--- | :--- | :--- | :--- | :--- | :--- |
| YouTube | Data Saver (Mobile) | 360p / 480p | 550-880 kbps | 250-400 MB/hr | 2.5-4.0 hours |
| Netflix | Save Data (Mobile) | Sub-SD / SD | ~370 kbps | ~166.7 MB/hr | ~6.0 hours |
| Netflix | Low (Web Profile) | SD (480p) | ~667 kbps | Up to 300 MB/hr | ~3.3 hours |
| Twitch | 360p Transcode | 360p30 | 600-800 kbps | 270-360 MB/hr | 2.8-3.7 hours |
| Twitch | 480p Transcode | 480p30 | 900-1,200 kbps | 405-540 MB/hr | 1.8-2.5 hours |

---

## 4. Media Client Configuration: Cache Clamping & Format Selection

Unchecked media players prefetch minutes of forward video data that are lost if the stream is paused or interrupted. Restricting buffer sizes and specifying exact stream identifiers keeps consumption aligned with playback time.

### MPV Configuration (`~/.config/mpv/mpv.conf`)
Save the following configuration to `~/.config/mpv/mpv.conf` to clamp the buffer cache to 15 seconds and force AV1 and Opus streams:

```ini
# ~/.config/mpv/mpv.conf - 1GB / 12-Hour Operational Profile

# 1. Restrict buffer readahead to prevent forward prefetch data waste
cache=yes
demuxer-max-bytes=4MiB
demuxer-max-back-bytes=1MiB
demuxer-readahead-secs=15
demuxer-hysteresis-secs=5

# 2. Hardware decoding
vo=gpu
gpu-context=auto
hwdec=auto-safe

# 3. Restrict stream format to AV1 (360p/240p) + Opus (<55 kbps)
ytdl=yes
ytdl-format="bv[vcodec^=av01][height<=360][tbr<=140]+ba[acodec=opus][abr<=55]/bv[vcodec^=vp9][height<=360][tbr<=140]+ba[acodec=opus][abr<=55]/bv[height<=240][tbr<=100]+ba[abr<=50]/worst"
```

### Direct CLI Playback with MPV
To stream on-demand content with explicit bitrate rules:

```bash
mpv --ytdl-format="bv[vcodec^=av01][height<=360][tbr<=140]+ba[acodec=opus][abr<=55]/bv[vcodec^=vp9][height<=360][tbr<=140]+ba[acodec=opus][abr<=55]/b[height<=360][tbr<=175]/worst" \
    --demuxer-max-bytes=4M \
    --demuxer-readahead-secs=15 \
    "[https://www.youtube.com/watch?v=VIDEO_ID](https://www.youtube.com/watch?v=VIDEO_ID)"
```

### Streamlink CLI for Live Video
When ingesting live broadcasts (such as Twitch), strip client-side web overhead and restrict segment caching:

```bash
streamlink --default-stream "360p,worst" \
           --stream-sorting-excludes ">360p" \
           --ringbuffer-size 4M \
           --stream-segment-threads 1 \
           --stream-segment-attempts 3 \
           --player mpv \
           --player-args "--cache=yes --demuxer-max-bytes=4M --demuxer-readahead-secs=15" \
           "[https://www.twitch.tv/CHANNEL_NAME](https://www.twitch.tv/CHANNEL_NAME)"
```

### Firefox Browser Engine Tuning
When viewing video through Firefox, navigate to `about:config` and adjust the media buffer thresholds:
* `media.cache_readahead_limit` $\rightarrow$ `15` (reduces forward prefetch buffer from 60 seconds to 15 seconds)
* `media.cache_resume_threshold` $\rightarrow$ `5` (prevents requesting new media chunks until the active buffer drops to 5 seconds)

---

## 5. Linux Traffic Shaping: Kernel-Level Bandwidth Caps

To guarantee that aggregate data transfer does not exceed the 170.37 kbps ceiling during visual spikes or codec bitrate surges, apply kernel-level traffic policing.

### Linux Traffic Control (`tc`) via Token Bucket Filter (`tbf`)
The Token Bucket Filter allows burst handling while enforcing a strict sustained ceiling of 175 kbps:

```bash
#!/usr/bin/env bash
# File: limit_bandwidth.sh
# Purpose: Clamp interface eth0 to 175 kbps using Linux tc

IFACE="eth0"
RATE="175kbit"
BURST="10k"
LATENCY="50ms"

# Clear existing qdisc
sudo tc qdisc del dev "$IFACE" root 2>/dev/null |

| true

# Apply Token Bucket Filter (TBF)
sudo tc qdisc add dev "$IFACE" root tbf \
    rate "$RATE" \
    burst "$BURST" \
    latency "$LATENCY"

echo "[+] Traffic shaping active on ${IFACE}: Max throughput clamped to ${RATE}."
```

To remove the limit after playback:

```bash
sudo tc qdisc del dev eth0 root
```

### Alternative: Wondershaper
To manage both ingress and egress bandwidth:

```bash
# Throttle download to 175 kbps and upload to 64 kbps
sudo wondershaper -a wlan0 -d 175 -u 64

# Check active status
sudo wondershaper -sa wlan0

# Remove limits
sudo wondershaper -ca wlan0
```

---

## 6. Android Hotspot Optimization via ADB (Preserving Tethering)

When tethering from an Android device, background app syncing, store updates, and system telemetry can consume hundreds of megabytes within a few hours.

### The Hotspot Failure Mechanism
Running the following command enables global Data Saver:
```bash
adb shell cmd netpolicy set restrict-background true
```
Under global Data Saver (`RESTRICT_BACKGROUND_ON`), Android's `TetheringService` and `NetworkPolicyManagerService` enforce strict upstream conservation. The kernel's netfilter/eBPF rules (`bw_costly_shared`) immediately drop packet forwarding across tethered interfaces (`ap0`, `rndis0`, `wlan1`), terminating hotspot connectivity for external clients.

### The Hotspot Preservation Solution
To stop background host data consumption while preserving mobile hotspot forwarding:
1. Ensure global Data Saver is **OFF** (`cmd netpolicy set restrict-background false`).
2. Add non-system UIDs individually to `restrict-background-blacklist`.
3. Set AppOps `RUN_IN_BACKGROUND` and `RUN_ANY_IN_BACKGROUND` to `ignore`.
4. Demote non-system packages to the `restricted` App Standby bucket (`cmd usagestats set-app-standby-bucket <pkg> restricted`), which halts opportunistic background data jobs (`JobScheduler`) and alarms.

### Automated Background Data Control (One-Line curl Commands)

Apply, inspect, or revert background traffic controls over ADB in a single command without cloning the repository:

#### Check Device Root and OEM Unlock Status
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- check
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- check
```

#### Apply Restrictions (Protect Hotspot)
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- apply
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- apply
```

#### Inspect Policy Status
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- status
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- status
```

#### Revert Restrictions
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- revert
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh | bash -s -- revert
```

Fish shell alternative:
```fish
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.fish | fish -s -- apply
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.fish | fish -s -- apply
```

### Fast On-Device Bash Optimization Script
Executes inside a single `adb shell` session to prevent command round-trip latency:

```bash
#!/usr/bin/env bash
# File: optimize_android_hotspot.sh
# Purpose: Restrict background apps over ADB while preserving mobile hotspot forwarding

set -euo pipefail

adb shell 'sh -s' << 'EOF'
echo "[*] Keeping global Data Saver OFF to protect hotspot forwarding..."
cmd netpolicy set restrict-background false

echo "[*] Processing third-party packages..."
for pkg in $(pm list packages -3 | sed 's/^package://'); do
    [ -z "$pkg" ] && continue

    # Extract package UID
    uid=$(dumpsys package "$pkg" 2>/dev/null | grep -m1 "userId=" | sed -E 's/.*userId=([0-9]+).*/\1/')

    if [ -n "$uid" ]; then
        # 1. Blacklist UID from background cellular data
        cmd netpolicy add restrict-background-blacklist "$uid" >/dev/null 2>&1

        # 2. Block background execution & wakeups
        cmd appops set "$pkg" RUN_IN_BACKGROUND ignore >/dev/null 2>&1
        cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1

        # 3. Demote package to the restricted App Standby bucket
        cmd usagestats set-app-standby-bucket "$pkg" restricted >/dev/null 2>&1

        echo "Optimized: $pkg (UID: $uid)"
    fi
done

echo "[+] Android background hardening complete. Hotspot remains functional."
EOF
```

### Fast On-Device Bash Reversal Script
Restores default AppOps states, clears UIDs from the blacklist, and returns packages to active status:

```bash
#!/usr/bin/env bash
# File: revert_android_hotspot.sh
# Purpose: Revert background restrictions to Android defaults

set -euo pipefail

adb shell 'sh -s' << 'EOF'
echo "[*] Ensuring global Data Saver remains off..."
cmd netpolicy set restrict-background false

echo "[*] Restoring third-party packages..."
for pkg in $(pm list packages -3 | sed 's/^package://'); do
    [ -z "$pkg" ] && continue

    uid=$(dumpsys package "$pkg" 2>/dev/null | grep -m1 "userId=" | sed -E 's/.*userId=([0-9]+).*/\1/')

    if [ -n "$uid" ]; then
        # 1. Remove UID from background blacklist
        cmd netpolicy remove restrict-background-blacklist "$uid" >/dev/null 2>&1

        # 2. Reset AppOps states to system default
        cmd appops set "$pkg" RUN_IN_BACKGROUND default >/dev/null 2>&1
        cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND default >/dev/null 2>&1

        # 3. Return App Standby bucket to active system evaluation
        cmd usagestats set-app-standby-bucket "$pkg" active >/dev/null 2>&1

        echo "Restored: $pkg (UID: $uid)"
    fi
done

echo "[+] System defaults restored."
EOF
```

### Fish Shell Optimization Script

```fish
#!/usr/bin/env fish
# File: optimize_android_hotspot.fish

echo "[*] Ensuring global Data Saver is OFF..."
adb shell cmd netpolicy set restrict-background false

set packages (adb shell pm list packages -3 | string replace "package:" "" | string trim)

for pkg in $packages
    test -z "$pkg"; and continue

    set uid (adb shell dumpsys package $pkg | string match -r "userId=\\d+" | head -n 1 | string replace "userId=" "" | string trim)

    if test -n "$uid"
        adb shell cmd netpolicy add restrict-background-blacklist $uid >/dev/null 2>&1
        adb shell cmd appops set $pkg RUN_IN_BACKGROUND ignore >/dev/null 2>&1
        adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1
        adb shell cmd usagestats set-app-standby-bucket $pkg restricted >/dev/null 2>&1

        echo "Optimized: $pkg (UID: $uid)"
    end
end

echo "[+] Android hardening applied. Hotspot routing preserved."
```

### Fish Shell Reversal Script

```fish
#!/usr/bin/env fish
# File: revert_android_hotspot.fish

echo "[*] Ensuring global Data Saver is OFF..."
adb shell cmd netpolicy set restrict-background false

set packages (adb shell pm list packages -3 | string replace "package:" "" | string trim)

for pkg in $packages
    test -z "$pkg"; and continue

    set uid (adb shell dumpsys package $pkg | string match -r "userId=\\d+" | head -n 1 | string replace "userId=" "" | string trim)

    if test -n "$uid"
        adb shell cmd netpolicy remove restrict-background-blacklist $uid >/dev/null 2>&1
        adb shell cmd appops set $pkg RUN_IN_BACKGROUND default >/dev/null 2>&1
        adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND default >/dev/null 2>&1
        adb shell cmd usagestats set-app-standby-bucket $pkg active >/dev/null 2>&1

        echo "Restored: $pkg (UID: $uid)"
    end
end

echo "[+] Defaults restored."
```

### Verification Commands
Verify that background restrictions are active and tether forwarding is functional:

```bash
# 1. Check global Data Saver status (Expected: Restrict background: false)
adb shell cmd netpolicy get restrict-background

# 2. View blacklisted UIDs under NetworkPolicy
adb shell dumpsys netpolicy | grep -A 25 "Restricted UIDs:"

# 3. Check App Standby bucket of a specific app (Expected: restricted)
adb shell cmd usagestats get-app-standby-bucket com.example.app

# 4. Check active tethering interfaces
adb shell dumpsys connectivity tethering
```

---

## 7. Configuration Reference Matrix

| Layer | Configuration | Objective | Failure Mode If Omitted |
| :--- | :--- | :--- | :--- |
| **Bitrate Target** | Combined audio/video $\le$ 170.37 kbps | Strict 12-hour limit on 1 GB | Quota depleted before 12 hours |
| **Resolution Target** | 360p ($640 \times 360$) | 43.75% pixel reduction vs. 480p | 480p exhausts quota in ~7.4 hours |
| **Video Codec** | AV1 (`av01` / itag 396) | 120-140 kbps video stream | H.264/VP9 exceed bandwidth ceiling |
| **Audio Codec** | Opus (itag 249 at ~52 kbps) | 60% reduction vs. 128 kbps AAC | Audio alone consumes 75% of budget |
| **Player Buffer** | `demuxer-max-bytes=4M` | Clamp lookahead to $\le$ 15 seconds | Prefetched buffer chunks are wasted |
| **Traffic Shaper** | Linux `tc tbf` at 175 kbps | Clamp sustained interface throughput | Bitrate spikes breach the budget |
| **Host Tethering** | Per-UID AppOps + Standby Buckets | Keep `restrict-background false` | Global Data Saver breaks hotspot |
