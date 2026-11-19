# Cellular Data Reduction and Selective Background Traffic Control on Android

Author: Dev Borah (bitzzdev)  
Date: November 2026  
Status: Evaluated and Verified

## Abstract

When sharing a mobile internet connection via Wi-Fi hotspot on Android, bandwidth contention between device background activity and connected clients causes packet delay, data depletion, and tethering instability. Turning on Android system Data Saver disables Wi-Fi tethering entirely due to system-level service mutual exclusion. This paper evaluates granular traffic controls across unprivileged ADB and rooted Android devices. It distinguishes documented Android behavior from device-specific behavior that requires testing. The recommended default uses per-UID NetworkPolicy restrictions and app standby controls, leaves global tethering and radio settings unchanged, and keeps Android Data Saver disabled while hotspot use is required. No fixed data-saving percentage is claimed without device-level measurements.

---

## 1. The Mobile Hotspot and Data Saver Dilemma

Android implements network policy management in `com.android.server.net.NetworkPolicyManagerService`. When system Data Saver is enabled, Android's AOSP Settings implementation disables tethering and portable hotspots. This is an explicit platform behavior, not a per-device benchmark. Keep Data Saver off when hotspot availability is a requirement. The scripts therefore do not enable global Data Saver; they apply per-UID restrictions to selected installed apps instead.

To conserve cellular bandwidth while keeping tethering active, traffic optimization must be applied at the per-package and per-UID level rather than using the global Data Saver toggle.

---

## 2. Bandwidth Drain Mechanisms in Non-Essential Apps

Retail, food delivery, and commercial applications (Amazon, Flipkart, Myntra, Ajio, Meesho, Blinkit, Zepto, Swiggy, Zomato) generate continuous background data traffic through several vectors:
- Promotional notification payloads: Rich push notifications containing pre-cached banners, high-resolution product thumbnails, and tracking beacons downloaded prior to display.
- Telemetry and analytics intervals: Periodic device telemetry, location pings, and cart sync jobs scheduled through `WorkManager` or `JobScheduler`.
- App-standby wakeups: Frequent background execution wakes the cellular radio out of low-power RRC (Radio Resource Control) idle states, increasing power draw and baseline data overhead.

In contrast, real-time communication platforms (WhatsApp, Telegram, Signal, Instagram direct messages, VoIP services) require socket access and Google Play Services Firebase Cloud Messaging (FCM) high-priority channel delivery to receive calls and messages without delay.

---

## 3. Targeted Control Architectures via ADB

Granular control without root privileges is accomplished through two Android subsystem interfaces: `appops` and `netpolicy`.

### 3.1 Notification Suppression (`POST_NOTIFICATION`)
By setting `POST_NOTIFICATION` to `ignore`, the application process is prevented from posting alerts to the notification tray. For many shopping apps, suppressing the notification display breaks the download trigger for rich media assets:

```bash
cmd appops set <package_name> POST_NOTIFICATION ignore
```

To restore:
```bash
cmd appops set <package_name> POST_NOTIFICATION allow
```

### 3.2 Background Execution Denial (`RUN_ANY_IN_BACKGROUND` and `RUN_IN_BACKGROUND`)
The `RUN_ANY_IN_BACKGROUND` and `RUN_IN_BACKGROUND` operations restrict the app from running arbitrary background services, background broadcast receivers, or background tasks when the user is not actively interacting with the UI:

```bash
cmd appops set <package_name> RUN_ANY_IN_BACKGROUND ignore
cmd appops set <package_name> RUN_IN_BACKGROUND ignore
```

This prevents shopping and delivery apps from starting background network sync jobs while leaving high-priority messaging apps untouched.

### 3.3 Standby Bucket Clamping (`usagestats set-app-standby-bucket`)
Android evaluates app power and network allowances using Standby Buckets (`active`, `working_set`, `frequent`, `rare`, `restricted`). On Android 12 and later, the `restricted` bucket applies the strongest standby restrictions. Current Android documentation describes a once-daily batched job window and a one-alarm-per-day limit for the restricted bucket, with exemptions and charging or unmetered-network exceptions. Exact behavior varies by Android version and OEM implementation. Network and job quotas must not be treated as identical across all releases.

```bash
cmd usagestats set-app-standby-bucket <package_name> restricted
```

### 3.4 Per-UID Network Blacklisting (`netpolicy restrict-background-blacklist`)
Android's network policy daemon allows blacklisting specific UIDs from using cellular data in the background, even when global Data Saver is turned off:

1. Resolve the package UID:
   ```bash
   cmd package list packages -U | grep <package_name>
   ```
2. Add UID to background restriction blacklist:
   ```bash
   cmd netpolicy add restrict-background-blacklist <UID>
   ```
3. To restore background access:
   ```bash
   cmd netpolicy remove restrict-background-blacklist <UID>
   ```

Because this rule targets only specified UIDs, the mobile hotspot routing engine remains fully operational.

---

## 4. Hardware and Kernel-Level Packet Filtering (Rooted Devices)

While ADB user-level commands enforce framework policy, rooted environments allow hardware and kernel-level enforcement via Linux Netfilter (`iptables` / `ip6tables`).

### 4.1 Cellular Interface Socket Drops
Mobile data interfaces in Android are typically identified as:
- Qualcomm chipsets: `rmnet+` (e.g. `rmnet_data0`, `rmnet_mhi0`)
- MediaTek chipsets: `ccmni+`
- Samsung Exynos chipsets: `pdp+`
- General USB / WWAN modems: `wwan+`

By inserting a netfilter rule matching the application UID on the cellular output chain:
```bash
iptables -I OUTPUT -o rmnet+ -m owner --uid-owner <UID> -j DROP
ip6tables -I OUTPUT -o rmnet+ -m owner --uid-owner <UID> -j DROP
```
This filters locally generated OUTPUT traffic owned by the selected UID on matching interfaces. It is not a guarantee of zero bytes on every device: interface naming, IPv6 behavior, vendor firewall chains, and traffic generated by system services vary. Forwarded hotspot client packets normally traverse forwarding paths rather than a local app UID OUTPUT path, but hotspot behavior still requires an on-device test before treating root rules as safe.

### 4.2 Bootloader and OEM Unlocking Diagnostics
Root access requires an unlocked bootloader. The script queries vendor property keys to determine device readiness:
- `sys.oem_unlock_allowed`: Reports whether the user has enabled the "OEM unlocking" switch in Developer Options (`1` allowed, `0` prohibited).
- `ro.boot.flash.locked`: Reports physical bootloader lock state (`1` locked, `0` unlocked).
- `ro.boot.verifiedbootstate`: Verifies cryptographic boot state (`green` locked official, `orange`/`yellow` unlocked).

When a non-root device has `sys.oem_unlock_allowed = 0`, the script provides clear guidance on unlocking Developer Options, enabling the toggle, and understanding the security and capability advantages of kernel-level iptables isolation.

---

## 5. Transport Layer and Cellular Modem Optimization

### 5.1 Cellular and tethering settings

The automation does not change `mobile_data_always_on`, `tether_dun_required`, or `tether_offload_disabled`. These are global, OEM- or carrier-sensitive settings. Changing the DUN requirement can conflict with carrier provisioning, and forcing offload values is not required for per-app background restrictions. Preserve the device's existing values to avoid introducing a hotspot regression.

### 5.2 Encrypted Ad and Tracker Blocking via Private DNS (DNS-over-TLS)
Third-party applications embed multiple advertising and analytics SDKs that continuously transmit telemetry beacons. Configuring system Private DNS with an ad-blocking resolver halts these connections at the initial name resolution step:
```bash
settings put global private_dns_mode hostname
settings put global private_dns_specifier dns.adguard-dns.com
```
Private DNS is an optional, user-selected resolver setting. It can prevent lookups for domains that the resolver blocks, but it does not block hard-coded IP connections or guarantee a particular data reduction. The automation does not change Private DNS automatically.

### 5.3 Tethering hardware offload

The scripts leave the tethering offload and DUN settings untouched. AOSP defines `tether_offload_disabled` as a switch that disables communication with the tethering offload HAL, while `tether_dun_required` controls carrier DUN requirements. Neither should be forced as a generic internet optimization.

---

## 6. Accessibility Service and UI Automation for Vendor Skins

### 6.1 The Vendor Skin NetPolicy Limitation
Heavily customized OEM skins (ColorOS, MIUI, FuntouchOS, One UI) often execute proprietary security managers that reset `cmd netpolicy` blacklists upon application reboot.

However, all OEM firmware respects the standard user-facing switch inside:
`Settings -> Apps -> App Info -> [Package] -> Mobile data & Wi-Fi -> Background data`.

### 6.2 Accessibility Traversal Architecture
To provide persistent control across heavily skinned devices without root:
1. An Accessibility Service (`android/accessibility-service/`) registers for `TYPE_WINDOW_STATE_CHANGED`.
2. The orchestrator script launches the App Info intent for each target package:
   ```bash
   am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:<target_pkg>"
   ```
3. The Accessibility Service parses the active `AccessibilityNodeInfo` tree, identifies the data settings entry, navigates into the sub-menu, checks the "Background data" switch state, and triggers `ACTION_CLICK` if active.
4. It calls `performGlobalAction(GLOBAL_ACTION_BACK)` to return cleanly, allowing the loop to proceed to the next package.

---

## 7. Comparative Performance Matrix

| Metric / Mechanism | Default Android | Global Data Saver | Substrate Selective (ADB) | Substrate Root (iptables) |
| :--- | :--- | :--- | :--- | :--- |
| **Wi-Fi Hotspot Usability** | Functional | Disabled by AOSP Settings while Data Saver is on | Expected to remain available; device test required | Device test required |
| **Retail Background Data** | Unmeasured | Restricted by selected UID policy and standby controls | Restricted by selected UID policy and standby controls | Interface- and device-dependent kernel filtering |
| **WhatsApp / Telegram Calls** | Device-dependent | May be restricted by global policy | Excluded from target allowlist | Excluded from target allowlist |
| **Vendor Skin Persistence** | N/A | OEM-dependent | OEM-dependent | Root-hook and OEM-dependent |
| **Modem Idle Power Draw** | Not measured | Not measured | Not measured | Not measured |
| **Ad / Tracker Payload Waste** | Not measured | Resolver-dependent | Resolver-dependent | Resolver- and firewall-dependent |

---

## 8. Verification and Measurement

1. Monitor background UID network statistics:
   ```bash
   adb shell dumpsys netstats detail
   ```
2. Verify blacklisted UIDs:
   ```bash
   adb shell cmd netpolicy list restrict-background-blacklist
   ```
3. Inspect active kernel iptables rules (root mode):
   ```bash
   adb shell su -c "iptables -S OUTPUT | grep DROP"
   ```
4. Test hotspot operation with a connected client, then verify client DNS, HTTPS, and sustained downloads. Test messaging delivery separately. Record before/after UID byte counters from `dumpsys netstats`; do not infer a percentage without measurements.
