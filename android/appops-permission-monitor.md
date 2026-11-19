# AppOps Permission Monitor on Realme UI

## Why AppOps commands can fail

On some Realme UI and related ColorOS builds, Android's ADB shell user is not
allowed to change AppOps modes while the OEM permission monitor is active.
Commands such as:

```sh
adb shell cmd appops set com.flipkart.android RUN_ANY_IN_BACKGROUND ignore
adb shell cmd appops set com.flipkart.android POST_NOTIFICATION ignore
```

may fail with a `SecurityException` stating that UID 2000 does not have
`android.permission.MANAGE_APP_OPS_MODES`.

USB debugging being enabled does not necessarily grant this permission. This
is an OEM permission restriction, not a Bash, Fish, or ADB transport error.

## Check the Developer options

On the Realme C11 RMX3231 running Android 11, check this location:

1. Open **Settings**.
2. Open **Additional settings**.
3. Open **Developer options**.
4. Look for **Disable permission monitoring**.

The toggle name and availability depend on the installed Realme UI firmware.
Some firmware versions do not expose it. Do not assume that a similarly named
OEM option is equivalent, and do not change unrelated security settings just
to make an ADB command work.

## Security implications

Disabling permission monitoring weakens an OEM security safeguard. It can
change how Android handles permission-related operations initiated through
ADB. Only change it if you understand and accept that trade-off.

If the option is available and you choose to proceed:

1. Enable **Disable permission monitoring**.
2. Reboot the phone if the firmware requires it. The Substrate scripts advise
   rebooting before retrying.
3. Reconnect ADB and confirm the device is authorized:
   ```sh
   adb devices
   ```
4. Rerun the relevant Substrate traffic-control command.
5. Check the AppOps modes and confirm they show the requested values.

For example:

```sh
adb shell cmd appops get com.flipkart.android POST_NOTIFICATION
adb shell cmd appops get com.flipkart.android RUN_ANY_IN_BACKGROUND
```

The expected mode after a successful restriction is `ignore`. Check each
operation separately. A successful command exit alone is not a substitute for
reading the resulting mode.

## If the toggle is missing or AppOps remains denied

Do not unlock the bootloader, root the phone, or attempt to grant
`MANAGE_APP_OPS_MODES` with an unsupported permission command just to bypass
the restriction.

The Substrate scripts continue with controls that the firmware permits:

- The app's UID can be added to Android's background metered-network blacklist.
- The app can be moved to the `restricted` standby bucket, subject to Android
  version and OEM behavior.
- The scripts report a partial result when AppOps is refused.

These controls do not prove that notification suppression or every background
execution restriction was applied. Keep the partial-result warning visible
when reporting the outcome.

## Hotspot considerations

Keep global Data Saver disabled when hotspot availability is required. AOSP
Settings disables portable hotspot use while Data Saver is enabled. The
Substrate hotspot profile therefore uses per-UID restrictions instead of
turning on global Data Saver.

After changing any OEM permission setting or rerunning the profile, test the
hotspot from a second device. Confirm that it can obtain an IP address, resolve
DNS, open HTTPS sites, and sustain a download.

## Related documentation

- [Cellular data and background traffic management](cellular-data-notification-saver.md)
- [Realme C11 RMX3231 performance and battery log](realme-c11-rmx3231-optimization.md)
- [Cellular data and hotspot optimization research](../papers/cellular-data-hotspot-optimization.md)
