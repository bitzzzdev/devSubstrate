# Legacy Launcher Installation on Arch Linux

Automated installation script for Legacy Launcher (Minecraft client), desktop entry integration, and icon registration.

---

## Prerequisites

Ensure Java 21 JRE is installed:

```bash
sudo pacman -S jre21-openjdk
```

Place the required launcher assets in your `Downloads` directory:
- `LegacyLauncher.jar` located at `~/Downloads/LegacyLauncher.jar`
- `mc.png` (application icon) located at `~/Downloads/mc.png`

---

## Automated Installation (One-Line curl Command)

Run the installation script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/scripts/install-legacy-launcher.sh | bash
```

---

## What the Script Does

1. Verifies that the required JAR file and icon exist in `~/Downloads/`.
2. Verifies that the Java runtime is available in PATH.
3. Creates the target directory `/opt/legacy-launcher`.
4. Moves the JAR and icon into `/opt/legacy-launcher/` with read permissions (`644`).
5. Generates the desktop entry at `/usr/share/applications/legacy-launcher.desktop`:
   - Executable command: `java -jar /opt/legacy-launcher/LegacyLauncher.jar`
   - Icon path: `/opt/legacy-launcher/mc.png`
   - Category: `Game`
6. Updates the desktop database via `update-desktop-database` so the launcher appears in your desktop application menu immediately.

---

## Verification

Launch from your desktop application launcher or run directly from the terminal:

```bash
java -jar /opt/legacy-launcher/LegacyLauncher.jar
```
