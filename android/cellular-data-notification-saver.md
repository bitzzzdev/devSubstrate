# Android Cellular Data and Background Traffic Management

Selective traffic control and notification pausing for Android devices over ADB to prevent background cellular bandwidth exhaustion while keeping Wi-Fi hotspot active and preserving high-priority notifications (WhatsApp, Instagram, Telegram).

---

## 1. Overview and Problem

Android's system Data Saver (`cmd netpolicy set restrict-background true`) disables Wi-Fi Hotspot (`SoftApManager`) because the operating system treats global background data restrictions and hotspot client routing as mutually exclusive.

If you turn on your mobile hotspot for a laptop, non-essential apps (Amazon, Flipkart, Myntra, Ajio, Meesho, Blinkit, Zepto, Swiggy, Zomato) continue running in the background. They download high-resolution marketing banners, rich push notifications, and tracking analytics. This drains cellular data and throttles hotspot bandwidth.

This guide provides automated scripts in **Bash** and **Fish** shell to:
- Silence and suppress non-essential retail and delivery notifications (`POST_NOTIFICATION ignore`).
- Halt arbitrary background tasks and broadcast wakeups (`RUN_ANY_IN_BACKGROUND ignore`).
- Blacklist specific app UIDs from background cellular data (`netpolicy add restrict-background-blacklist <UID>`).
- Keep WhatsApp, Instagram direct messages, Telegram, and incoming VoIP calls active in real time.
- Verify that Wi-Fi hotspot hardware offload remains enabled (`tether_offload_disabled 0`).

For the complete architectural evaluation and benchmarking analysis, see the research paper:  
[`papers/cellular-data-hotspot-optimization.md`](../../papers/cellular-data-hotspot-optimization.md).

---

## 2. Included Automation Scripts

Two scripts are available under `android/scripts/`:
- [`manage-shopping-traffic.sh`](scripts/manage-shopping-traffic.sh) (POSIX/Bash)
- [`manage-shopping-traffic.fish`](scripts/manage-shopping-traffic.fish) (Fish shell)

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

### Whitelisted Applications (Untouched)
- WhatsApp (`com.whatsapp`)
- Instagram (`com.instagram.android`)
- Telegram (`org.telegram.messenger`)
- Google Play Services (`com.google.android.gms` for FCM push delivery)

---

## 3. Usage Instructions

### Prerequisites
1. Enable **Developer Options** and **USB Debugging** on your Android device.
2. Connect your device via USB or Wireless ADB:
   ```bash
   adb devices
   ```

### Automated Execution (One-Line curl Commands)

Execute directly without cloning the repository or changing directories:

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

Fish shell alternative:
```fish
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.fish | fish -s -- pause
```

### Local Script Execution via Bash

```bash
cd android/scripts

# Restrict non-essential apps and protect hotspot
./manage-shopping-traffic.sh pause

# Inspect current AppOps restriction status
./manage-shopping-traffic.sh status

# Lift all restrictions when done
./manage-shopping-traffic.sh resume
```

### Execution via Fish Shell

```fish
cd android/scripts

# Restrict non-essential apps and protect hotspot
./manage-shopping-traffic.fish pause

# Inspect current AppOps restriction status
./manage-shopping-traffic.fish status

# Lift all restrictions when done
./manage-shopping-traffic.fish resume
```

---

## 4. Manual ADB Commands

If running commands individually:

### Step 1: Suppress Notification Media Downloads
```bash
adb shell cmd appops set in.amazon.mShop.android.shopping POST_NOTIFICATION ignore
```

### Step 2: Prevent Background Work and Broadcasts
```bash
adb shell cmd appops set in.amazon.mShop.android.shopping RUN_ANY_IN_BACKGROUND ignore
```

### Step 3: Block Background Cellular Sockets for App UID
```bash
# Lookup UID
UID=$(adb shell cmd package list packages -U in.amazon.mShop.android.shopping | sed -n 's/.*uid:\([0-9]*\).*/\1/p')

# Add to blacklist
adb shell cmd netpolicy add restrict-background-blacklist $UID
```

### Step 4: Verify Hotspot Acceleration
```bash
adb shell settings put global tether_offload_disabled 0
adb shell settings put global tether_dun_required 0
```

---

## 5. Verification

1. Verify blacklisted UIDs:
   ```bash
   adb shell cmd netpolicy list restrict-background-blacklist
   ```
2. Verify active hotspot traffic:
   ```bash
   adb shell dumpsys netstats detail
   ```
3. Open WhatsApp or send an Instagram DM: receipt remains instantaneous via FCM high-priority sockets, while retail promotional traffic is halted.
