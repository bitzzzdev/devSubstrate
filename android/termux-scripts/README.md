# Termux Local Scripts: Running Mobile and ADB Fixes On-Device

This directory contains executable scripts designed to run locally inside **Termux** on Android without requiring an external computer.

---

## 1. Execution Modes and Android Sandboxing

Android strictly isolates application sandboxes. When executing commands directly in Termux, scripts automatically detect and adapt to the active privilege level:

1. **Privileged Backend (Root / Shizuku / Local ADB Loopback):**
   - Has full access to Android framework services (`cmd netpolicy`, `cmd appops`, `pm trim-caches`, `settings`).
   - Achieves 100% feature parity with computer-connected ADB.

2. **Standard Unprivileged Termux Userland (Non-Root):**
   - Cannot directly modify global network policies or system AppOps of other packages.
   - Automatically executes non-root fallback actions: terminates active background worker processes (`am force-stop`, `pkill`), clears userland caches, and performs storage audits.
   - Prints an **Execution Audit** explaining exactly what succeeded in userland and what commands require ADB/root privileges.

---

## 2. Running Local ADB via Wireless Debugging (No PC Required)

To access the full set of ADB capabilities directly from within Termux on Android 11+:

1. Install Android tools inside Termux:
   ```bash
   pkg update && pkg install android-tools
   ```
2. On your phone, go to **Settings > Developer Options > Wireless Debugging**.
3. Tap **Pair device with pairing code**. Note the Wi-Fi pairing code, IP address, and port.
4. Run in Termux:
   ```bash
   adb pair 127.0.0.1:<pairing_port>
   # Enter the 6-digit code
   ```
5. Look at the primary port under "Wireless Debugging" (different from pairing port) and connect:
   ```bash
   adb connect 127.0.0.1:<main_port>
   ```
6. Verify connection:
   ```bash
   adb devices
   ```
Once connected, all scripts automatically detect the active loopback ADB session and execute full system commands directly.

---

## 3. Included Scripts

| Script (Bash) | Script (Fish) | Purpose | Userland Action | Privileged / ADB Action |
| --- | --- | --- | --- | --- |
| [`termux-manage-shopping-traffic.sh`](termux-manage-shopping-traffic.sh) | [`termux-manage-shopping-traffic.fish`](termux-manage-shopping-traffic.fish) | Pause/Resume retail app drain | Terminates active background processes | Suppresses notifications, denies background execution, blacklists cellular sockets |
| [`termux-hotspot-traffic-control.sh`](termux-hotspot-traffic-control.sh) | [`termux-hotspot-traffic-control.fish`](termux-hotspot-traffic-control.fish) | Hotspot background data protector | Kills non-whitelisted third-party tasks | Restricts `netpolicy` sockets, preserves WhatsApp, Telegram, Signal |
| [`termux-audit-storage.sh`](termux-audit-storage.sh) | [`termux-audit-storage.fish`](termux-audit-storage.fish) | Storage audit and cache trimmer | Cleans APT cache, `$TMPDIR`, reports large files | Executes system-wide `pm trim-caches` across all apps |

---

## 4. Usage Instructions

### Shopping App Traffic & Notification Pauser

In Bash:
```bash
./termux-manage-shopping-traffic.sh pause   # Restricts apps
./termux-manage-shopping-traffic.sh status  # Inspects AppOps
./termux-manage-shopping-traffic.sh resume  # Restores defaults
```

In Fish:
```fish
./termux-manage-shopping-traffic.fish pause
./termux-manage-shopping-traffic.fish status
./termux-manage-shopping-traffic.fish resume
```

### Hotspot Background Data Saver

In Bash:
```bash
./termux-hotspot-traffic-control.sh apply
./termux-hotspot-traffic-control.sh status
./termux-hotspot-traffic-control.sh revert
```

In Fish:
```fish
./termux-hotspot-traffic-control.fish apply
./termux-hotspot-traffic-control.fish status
./termux-hotspot-traffic-control.fish revert
```

### Storage Audit and Cache Trim

In Bash:
```bash
./termux-audit-storage.sh status
./termux-audit-storage.sh trim
```

In Fish:
```fish
./termux-audit-storage.fish status
./termux-audit-storage.fish trim
```

---

## 5. Execution Audit Output Format

When any script finishes running, it outputs a status summary:

```text
==================== EXECUTION AUDIT ====================
COMPLETED IN TERMUX NON-ROOT USERLAND:
  - Active background processes terminated for shopping apps.

WHAT STILL NEEDS ADB OR ROOT PRIVILEGES:
  1. Permanent notification suppression: 'cmd appops set <pkg> POST_NOTIFICATION ignore'
  2. Background execution denial: 'cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore'
  3. Cellular socket blacklist: 'cmd netpolicy add restrict-background-blacklist <UID>'

TIP TO RUN LOCALLY ON DEVICE WITHOUT A PC:
  Run 'pkg install android-tools' inside Termux, enable Wireless Debugging
  in Android Settings, and run 'adb pair localhost:<port>' followed by 'adb connect'.
==========================================================
```
