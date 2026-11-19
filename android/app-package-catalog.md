# Android app package catalog

This catalog is the canonical target list for the ADB and Termux Bash/Fish
traffic-control scripts. Each standalone script carries a generated copy of
the target package IDs so curl-based execution works offline; the CI parity
test checks that the copies match this file. It covers discretionary apps across shopping,
food delivery, social media, streaming, games, news and sports, and dating.

## Schema

The tab-separated file `app-package-catalog.tsv` has four columns:

1. `category`: functional category.
2. `package`: exact Android application package identifier.
3. `app`: display name.
4. `policy`: `restrict` or `keep`.

Only rows with policy `restrict` are included in the automatic profile.
The scripts compare each package identifier against the device's installed
package list. Missing packages are skipped. Exact package matching prevents
a similarly named app from being selected.

## Restriction behavior

For each installed target, the scripts attempt to:

- Set `POST_NOTIFICATION`, `RUN_ANY_IN_BACKGROUND`, and
  `RUN_IN_BACKGROUND` AppOps modes to `ignore`.
- Move the app to Android's `restricted` standby bucket.
- Add its UID to the background metered-network restriction blacklist.
- Apply cellular-interface packet drops only when root is already available.

AppOps may be refused by Realme UI or another OEM permission monitor. In that
case, the scripts continue with the remaining supported controls and return
a partial-result status. They do not unlock the bootloader or grant
unsupported permissions.

## Exclusions

Rows marked `keep` are not automatically restricted. This includes
messaging, Google core services, maps, email, payments, banking, and transport
apps. The catalog intentionally avoids Android system packages and does not
attempt to disable, uninstall, force-stop, or block foreground use.

Instagram is included under `social`. WhatsApp, Telegram, and Signal remain
excluded. Hotspot routing and global Data Saver settings are not changed.

## Package identifier maintenance

Package identifiers can change between app editions, regional variants, and
store releases. An uninstalled or renamed package is simply skipped. Treat
this list as a maintained candidate catalog, not proof that every identifier
is current on every device. Review package names against the installed app
inventory before adding new entries. Do not add banking, authentication,
emergency, system, or core communication apps to the `restrict` policy.

## Coverage

- 97 discretionary app package candidates marked `restrict`.
- 16 protected or excluded package candidates marked `keep`.
- 11 categories represented.
