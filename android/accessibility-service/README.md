# Substrate Android Accessibility Service: Background Data Automation

An automated Android Accessibility Service designed to navigate system App Info settings and toggle off the **Background data** switch for high-consumption applications.

---

## 1. Problem and Architecture

On stock Android (AOSP), setting network policy blacklists via ADB (`cmd netpolicy add restrict-background-blacklist <UID>`) prevents an app from communicating over background cellular connections.

However, heavily modified OEM skins (such as Oppo/Realme ColorOS, Xiaomi MIUI/HyperOS, Vivo FuntouchOS, and Samsung One UI) frequently implement proprietary firewall daemons, security center managers, and battery saver services. In many cases, these OEM layers either ignore ADB NetPolicy entries or reset them when the phone boots or an application is launched.

The only interface that OEM firmware consistently respects is their own native Settings application:
`Settings -> Apps -> App Info -> [Target App] -> Mobile data & Wi-Fi -> Background data`.

This Accessibility Service provides programmatic UI traversal:
1. Listens for window state changes when an app's Settings page is launched via ADB.
2. Locates the data consumption sub-menu ("Mobile data & Wi-Fi", "Data usage").
3. Inspects the "Background data" switch widget.
4. If the switch is active, performs `ACTION_CLICK` to toggle it off.
5. Performs `GLOBAL_ACTION_BACK` twice to return cleanly to the previous state, allowing the runner script to proceed to the next package.

---

## 2. Directory Layout

```text
android/accessibility-service/
├── AndroidManifest.xml
├── README.md
├── res/
│   ├── values/
│   │   └── strings.xml
│   └── xml/
│       └── accessibility_service_config.xml
└── src/
    └── main/
        ├── java/dev/substrate/dataautomation/
        │   └── BackgroundDataAutomationService.java
        └── kotlin/dev/substrate/dataautomation/
            └── BackgroundDataAutomationService.kt
```

---

## 3. Installation and Activation via ADB

Once compiled into an APK (`app-debug.apk`), you can install and activate the accessibility service completely over ADB without needing root access:

### Step 1: Install APK
```bash
adb install -r app-debug.apk
```

### Step 2: Grant and Enable Accessibility Service
```bash
adb shell settings put secure enabled_accessibility_services dev.substrate.dataautomation/.BackgroundDataAutomationService
adb shell settings put secure accessibility_enabled 1
```

### Step 3: Verify Service Status
```bash
adb shell settings get secure enabled_accessibility_services
```
Expected output includes:
`dev.substrate.dataautomation/.BackgroundDataAutomationService`

---

## 4. Running the Automation Loop

Use the automation command in `manage-shopping-traffic.sh` to iterate through all non-essential applications:

```bash
cd android/scripts
./manage-shopping-traffic.sh automate-ui
```

The script fires the application details intent for each target package:
```bash
adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:<target_package>"
```
The active Accessibility Service intercepts the screen, turns off background data, and returns, completely automating the setup across all retail and delivery applications.

---

## 5. Deactivation and Removal

To disable the service after configuration is complete:

```bash
adb shell settings put secure enabled_accessibility_services ""
adb shell settings put secure accessibility_enabled 0
adb uninstall dev.substrate.dataautomation
```
