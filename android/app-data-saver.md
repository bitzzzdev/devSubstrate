# Per-app background data saver through ADB

This tool applies Android NetworkPolicyManager per-UID background metered-data
restrictions to installed packages marked `restrict` in
`app-package-catalog.tsv`.

## Commands

Run from Arch Linux, Termux with a working ADB connection, or another host
with Android platform-tools:

```bash
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/android/scripts/app-data-saver.sh | bash -s -- apply
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/android/scripts/app-data-saver.sh | bash -s -- status
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/android/scripts/app-data-saver.sh | bash -s -- revert
```

The default state file is
`$XDG_STATE_HOME/devsubstrate/app-data-saver-uids.txt`, or
`$HOME/.local/state/devsubstrate/app-data-saver-uids.txt` when
`XDG_STATE_HOME` is unset. It records only UIDs newly added by this tool.
`revert` removes only those recorded entries. Restrictions that existed
before the tool ran are not removed.

## What the policy does

Android 11 exposes
`cmd netpolicy add restrict-background-blacklist UID`. This sets the
`POLICY_REJECT_METERED_BACKGROUND` policy for that UID. Android temporarily
allows a foreground app's metered traffic, then reapplies the restriction
when it returns to the background. It is a background metered-network
restriction, not a full mobile-data kill switch and not a Wi-Fi firewall.

The tool does not enable global Data Saver, change AppOps, alter standby
buckets, disable Wi-Fi, disable foreground mobile data, or change hotspot
settings.

## Safety and exclusions

- Only installed exact package IDs with catalog policy `restrict` are
  considered.
- Catalog `keep` package UIDs are protected. A restricted package sharing a
  UID with a protected package is skipped.
- Existing Data Saver allowlisted UIDs are preserved and skipped because
  setting a UID policy replaces its existing policy.
- Already blacklisted UIDs are left untouched and are not recorded for revert.
- Package UIDs are shared policy identities. If multiple packages share one
  UID, Android applies the policy to that UID, not to one package in isolation.
- OEM firmware can reject or alter NetworkPolicy behavior. The tool reads the
  blacklist back after applying and reports failures.

This does not change Realme's proprietary Network Access setting that can
disable an app's mobile data even while it is foregrounded. No supported
Realme UI 2 / Android 11 ADB interface for that OEM-specific toggle has been
verified.
