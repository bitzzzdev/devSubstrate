# Arch Linux (July 2026+) UKI Wi-Fi Fix (QCA9377 / ath10k / pci=realloc)

## Symptoms

- Qualcomm Atheros QCA9377 detected by `lspci`
- No Wi-Fi interface in `ip link`
- `dmesg` contains:

```
ath10k_pci: failed to iomap BAR0
ath10k_pci: failed to claim device: -5
ath10k_pci: probe with driver ath10k_pci failed with error -5

pci_bus 0000:00: Some PCI device resources are unassigned,
try booting with pci=realloc
```

## Cause

This installation uses a **Unified Kernel Image (UKI)**.

Editing:

```
/etc/default/grub
```

and running:

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

does **NOT** change the kernel command line.

Kernel parameters are embedded into the UKI instead. Arch's mkinitcpio uses `/etc/kernel/cmdline` by default when generating a UKI. :contentReference[oaicite:0]{index=0}

## Verify

Check the current kernel command line:

```bash
cat /proc/cmdline
```

Check if the system boots a UKI:

```bash
sudo bootctl list
```

Expected:

```
type: Boot Loader Specification Type #2 (UKI)
linux: /boot/EFI/Linux/arch-linux.efi
```

## Automated Fix (One-Line curl Commands)

Apply, inspect, or revert the `pci=realloc=on` parameter in `/etc/kernel/cmdline` and regenerate the Unified Kernel Image with a single command:

### Apply Fix
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/uki-qca9377-fix.sh | sudo bash -s -- apply
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/uki-qca9377-fix.sh | sudo bash -s -- apply
```

### Check Status
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/uki-qca9377-fix.sh | bash -s -- status
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/uki-qca9377-fix.sh | bash -s -- status
```

### Revert Fix
```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/uki-qca9377-fix.sh | sudo bash -s -- revert
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/uki-qca9377-fix.sh | sudo bash -s -- revert
```

Fish shell alternative:
```fish
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/uki-qca9377-fix.fish | sudo fish -s -- apply
# GitLab mirror:
curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/uki-qca9377-fix.fish | sudo fish -s -- apply
```

---

## Manual Fix Procedure

Edit:

```bash
sudo nano /etc/kernel/cmdline
```

Append:

```
pci=realloc=on
```

Example:

```
root=PARTUUID=... rw rootfstype=btrfs rootflags=subvol=@ zswap.enabled=0 pci=realloc=on
```

Regenerate the UKI:

```bash
sudo mkinitcpio -P
```

Reboot.

Verify:

```bash
cat /proc/cmdline
```

It should now contain:

```
pci=realloc=on
```

## Notes

Do **NOT** edit:

```
/etc/default/grub
```

for kernel parameters on this installation.

The active boot path is:

```
/boot/EFI/Linux/arch-linux.efi
```

The kernel command line comes from:

```
/etc/kernel/cmdline
```

Changing GRUB will not affect the running kernel because the firmware boots the UKI directly. mkinitcpio embeds `/etc/kernel/cmdline` into the generated UKI by default. :contentReference[oaicite:1]{index=1}

## Search keywords

UKI
Unified Kernel Image
mkinitcpio
/etc/kernel/cmdline
bootctl list
ath10k
QCA9377
failed to iomap BAR0
failed to claim device
pci=realloc
pci=realloc=on
Arch Linux July 2026
Omarchy
