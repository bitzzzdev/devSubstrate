# Android Cellular Data and Background Traffic Management

Selective traffic control and notification pausing for Android devices over ADB to prevent background cellular bandwidth exhaustion while keeping Wi-Fi hotspot active and preserving high-priority notifications (WhatsApp, Instagram, Telegram).

---

## 1. Overview and Problem

Android's system Data Saver (`cmd netpolicy set restrict-background true`) disables Wi-Fi Hotspot (`SoftApManager`) because the operating system treats global background data restrictions and hotspot client routing as mutually exclusive.

If you turn on your mobile hotspot for a laptop, non-essential apps (Amazon, Flipkart, Myntra, Ajio, Meesho, Blinkit, Zepto, Swiggy, Zomato) continue running in the background. They download high-resolution marketing banners, rich push notifications, and tracking analytics. This drains cellular data and throttles hotspot bandwidth.

This guide provides automated scripts in **Bash** and **Fish** shell to:
- Smart-detect root privilege and OEM unlocking status (`sys.oem_unlock_allowed` and `ro.boot.flash.locked`) to advise users on unlocking bootloaders for full kernel-level iptables isolation.
- Silence and suppress non-essential retail and delivery notifications (`POST_NOTIFICATION ignore`).
- Halt arbitrary background tasks and broadcast wakeups (`RUN_ANY_IN_BACKGROUND ignore` and `RUN_IN_BACKGROUND ignore`).
- Demote background retail apps to the `restricted` App Standby bucket (`cmd usagestats set-app-standby-bucket <pkg> restricted`).
- Blacklist specific app UIDs from background cellular data (`netpolicy add restrict-background-blacklist <UID>`).
- Apply kernel-level Netfilter (`iptables` / `ip6tables`) cellular packet dropping on rooted devices across `rmnet+`, `ccmni+`, and `pdp+` interfaces.
- Disable mobile data always active (`settings put global mobile_data_always_on 0`) to prevent idle cellular modem drain.
- Automate UI toggles via an Android Accessibility Service (`android/accessibility-service/`) or ADB UIAutomator traversal to handle OEM custom skins (ColorOS, MIUI, FuntouchOS, One UI).
- Keep WhatsApp, Instagram direct messages, Telegram, and incoming VoIP calls active in real time.
- Attempt to preserve the device's existing Wi-Fi hotspot offload behavior (`tether_offload_disabled 0`).

For the complete architectural evaluation and benchmarking analysis, see the research paper:  
[`papers/cellular-data-hotspot-optimization.md`](../papers/cellular-data-hotspot-optimization.md).

---

## 2. Included Automation Scripts and Tools

### Scripts under `android/scripts/`:
- [`manage-shopping-traffic.sh`](scripts/manage-shopping-traffic.sh) (POSIX/Bash)
- [`manage-shopping-traffic.fish`](scripts/manage-shopping-traffic.fish) (Fish shell)

### Companion Accessibility Service:
- [`android/accessibility-service/`](accessibility-service/README.md) (Automates Background Data toggles in native Settings)

### Target Applications
- Amazon India (`in.amazon.mShop.android.shopping`)
- Flipkart (`com.flipkart.android`)
- Myntra (`com.myntra.android`)
- Ajio (`com.ril.ajio`)
- Meesho (`com.meesho.supply`)
- Blinkit (`com.grofers.customerapp`)
- Zepto (`com.zeptoconsumerapp`)
- Swiggy (`in.swiggy.android`)
- Zomato (`com.application.zomato`)
- BigBasket (`com.bigbasket.mobileapp`)
- JioMart (`com.jpl.jiomart`)
- Nykaa (`com.fsn.nykaa`)
- Snapdeal (`com.snapdeal.main`)
- Tata CLiQ (`com.tul.tatacliq`)

### Whitelisted Applications (Untouched)
- WhatsApp (`com.whatsapp`)
- Instagram (`com.instagram.android`)
- Telegram (`org.telegram.messenger`)
- Signal (`org.thoughtcrime.securesms`)
- Google Play Services (`com.google.android.gms` for FCM push delivery)

---

## 3. Smart Root and OEM Unlocking Detection

Android devices vary by firmware and vendor lock state. The script checks:
1. **Root Access**: Verifies if `su` or `adb root` is functional. If present, the script activates direct kernel `iptables` rules that drop cellular packets (`-o rmnet+`) for targeted UIDs, providing complete hardware-level isolation.
2. **OEM Unlocking State (`sys.oem_unlock_allowed`)**: Verifies if Developer Options allows bootloader unlocking.
3. **Bootloader Flash Lock (`ro.boot.flash.locked`)**: Verifies whether the hardware bootloader is locked (`1`) or unlocked (`0`).

If root is missing and OEM unlocking is disabled, the script prints instructions:
```text
[!] COMPATIBILITY WARNING: OEM Unlocking is DISABLED on this device.
Current status: sys.oem_unlock_allowed=0

Why this matters:
Certain customized OEM skins (ColorOS, MIUI, FuntouchOS) occasionally reset
or ignore background NetPolicy blacklists when apps are restarted.
Enabling OEM unlocking allows bootloader unlocking and root access, which grants
hardware-level packet dropping via iptables and persistent background isolation.

How to enable OEM Unlocking:
  1. Open Settings -> About Phone.
  2. Tap 'Build Number' 7 times until Developer options are unlocked.
  3. Navigate to Settings -> System -> Developer Options.
  4. Toggle 'OEM unlocking' to ON (and ensure 'USB debugging' remains active).
  5. (Optional for root) Unlock bootloader in fastboot mode and flash Magisk.
  6. Run this script again for enhanced compatibility.
```

---

## 4. Usage Instructions

### Prerequisites
1. Enable **Developer Options** and **USB Debugging** on your Android device.
2. Connect your device via USB or Wireless ADB:
   ```bash
   adb devices
   ```

### Automated Execution (One-Line curl Commands)

Execute directly without cloning the repository or changing directories:

#### Check Device Root and OEM Unlock Status
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh | bash -s -- check
```

#### Pause Non-Essential Traffic
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh | bash -s -- pause
```

#### Check Restriction Status
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh | bash -s -- status
```

#### Resume Normal Background Traffic
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh | bash -s -- resume
```

#### Automate UI Background Data Toggles
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh | bash -s -- automate-ui
```

Fish shell alternative:
```fish
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.fish | fish -s -- pause
```

### Local Script Execution via Bash

```bash
cd android/scripts

# Check device root and OEM unlock status
./manage-shopping-traffic.sh check

# Restrict non-essential apps and protect hotspot
./manage-shopping-traffic.sh pause

# Inspect current AppOps and iptables restriction status
./manage-shopping-traffic.sh status

# Run UI automation to flip Background Data toggles in Settings
./manage-shopping-traffic.sh automate-ui

# Lift all restrictions when done
./manage-shopping-traffic.sh resume
```

### Execution via Fish Shell

```fish
cd android/scripts

# Check device root and OEM unlock status
./manage-shopping-traffic.fish check

# Restrict non-essential apps and protect hotspot
./manage-shopping-traffic.fish pause

# Inspect current AppOps restriction status
./manage-shopping-traffic.fish status

# Run UI automation to flip Background Data toggles in Settings
./manage-shopping-traffic.fish automate-ui

# Lift all restrictions when done
./manage-shopping-traffic.fish resume
```

---

## 5. Accessibility Service UI Automation

On devices where vendor firmware bypasses `cmd netpolicy`, use the Substrate Accessibility Service located in [`android/accessibility-service/`](accessibility-service/README.md).

### How it works:
1. The script runs `am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:<pkg>`.
2. The Accessibility Service detects the App Info window, enters "Mobile data & Wi-Fi", and locates the "Background data" toggle.
3. If active, it clicks the toggle to disable it, and triggers a back navigation.
4. The script automatically moves to the next app in the queue.

### Activation:
```bash
adb install -r android/accessibility-service/app-debug.apk
adb shell settings put secure enabled_accessibility_services dev.substrate.dataautomation/.BackgroundDataAutomationService
adb shell settings put secure accessibility_enabled 1
```

---

## 6. System-Wide Data Reduction Optimizations

### Disable Mobile Data Always Active
Android maintains the cellular radio in active standby when connected to Wi-Fi to provide faster handoffs. This consumes battery and allows background cellular pings:
```bash
adb shell settings put global mobile_data_always_on 0
```

### Enable Encrypted Ad-Blocking Private DNS (DNS-over-TLS)
Ad trackers and marketing analytics SDKs account for 15% to 30% of background cellular requests. Setting an ad-blocking DNS-over-TLS resolver blocks these domains before sockets are established:
```bash
adb shell settings put global private_dns_mode hostname
adb shell settings put global private_dns_specifier dns.adguard-dns.com
```
To restore standard automatic DNS:
```bash
adb shell settings put global private_dns_mode opportunistic
```

### Hardware Hotspot Acceleration
```bash
adb shell settings put global tether_offload_disabled 0
adb shell settings put global tether_dun_required 0
```

---

## 7. Verification

1. Verify blacklisted UIDs:
   ```bash
   adb shell cmd netpolicy list restrict-background-blacklist
   ```
2. Verify active hotspot traffic:
   ```bash
   adb shell dumpsys netstats detail
   ```
3. Verify kernel iptables cellular rules (if rooted):
   ```bash
   adb shell su -c "iptables -S OUTPUT | grep DROP"
   ```
4. Verify messaging:
   Open WhatsApp or send a message on Telegram. Receipt remains instantaneous via FCM high-priority sockets, while retail promotional traffic and background syncs remain blocked.
