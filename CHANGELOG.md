# Changelog

All notable changes to the `devSubstrate` repository are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Added Bash and Fish NetworkManager helpers to mark only the active Wi-Fi profile as metered, inspect its state, and restore automatic metered-state detection.
- Added a mocked regression test for metered-profile apply, status, revert, and missing-active-Wi-Fi behavior. Added Bash and Fish syntax checks to the development CI job.

### Fixed
- Corrected the Linux curl launcher's Wi-Fi data-reduction target to use NetworkManager metered signaling instead of disabling QCA9377 radio power saving. The hardware-specific QCA9377 action remains available under its own target.

### Added
- Added `network/internet-data-drain-reduction.md` with Fish and Bash command blocks for traffic accounting, NetworkManager metered profiles, rate-limited transfers, pacman download controls, Git and Docker cache practices, and Android per-app data restrictions.
- Added `ai-providers/openrouter-free-coding-models.md` with a dated OpenRouter free coding model catalogue, upstream inference provider notes, tool support, privacy constraints, rate limits, and model expiry warnings.
- Added `android/scripts/app-data-saver.sh` to apply, inspect, and revert per-app background metered-data restrictions through Android 11 NetPolicy. It preserves allowlisted UIDs and protected shared UIDs without enabling global Data Saver.
- Added a mocked ADB regression test for apply, status, allowlist preservation, shared-UID exclusions, and scoped revert.

### Added
- Added `android/app-package-catalog.tsv` with discretionary app package candidates across shopping, social, streaming, games, news, sports, food delivery, and dating. Instagram is now included; messaging, payment, core Google, and transport apps are explicitly excluded.
- Expanded the ADB and Termux Bash/Fish traffic profiles to apply restrictions only to exact catalog package IDs installed on the device. Added catalog documentation and a parity regression test.

### Fixed
- Kept the hotspot stage running when the shopping stage reports partial success due to OEM AppOps permission-monitor restrictions. Added a development-branch Android shell validation job and a mocked regression test for the combined curl profile.

### Changed
- Made Android curl option 2 default to the `all` profile, applying shopping-app controls and the hotspot-safe third-party background profile without an extra prompt.
- Removed automatic writes to `mobile_data_always_on`, `tether_dun_required`, and `tether_offload_disabled` from Android ADB and Termux traffic scripts. Per-app restrictions do not require changing global carrier or tethering settings.
- Revised the cellular and hotspot research paper to remove unmeasured data-saving percentages and distinguish documented Android behavior from device-specific results.

### Added
- Added `android/appops-permission-monitor.md` with Realme UI and ColorOS troubleshooting for ADB AppOps denials, including the Developer options location, security trade-offs, verification commands, and fallback behavior.

- Free-tier Flash model and coding-agent integration reference `ai-providers/free-ai-api-providers-opencode-guide.md`, covering provider endpoints, model catalogs, quota snapshots, OpenCode, Kilo CLI, Continue.dev, Aider, and OpenAI SDK configuration.
- Smart root privilege and OEM unlocking diagnostics (`check` action) across `manage-shopping-traffic.sh`, `manage-shopping-traffic.fish`, `hotspot-background-traffic-control.sh`, and Termux traffic scripts.
- Kernel-level Netfilter (`iptables` / `ip6tables`) cellular packet dropping on rooted devices across `rmnet+`, `ccmni+`, `pdp+`, and `wwan+` interfaces to ensure zero background cellular leakage.
- Android Accessibility Service `BackgroundDataAutomationService` (`android/accessibility-service/`) in Kotlin and Java with manifest, XML config, and ADB enablement commands to automate toggling Background Data in native Settings across custom OEM firmware (ColorOS, MIUI, FuntouchOS, One UI).
- UI automation command (`automate-ui`) in `manage-shopping-traffic.sh` and `manage-shopping-traffic.fish` integrating Accessibility Service and UIAutomator node traversal.
- Idle cellular modem optimization (`settings put global mobile_data_always_on 0`) and encrypted ad-blocking Private DNS (DNS-over-TLS) configuration.
- Corporate release document suite: `TERMS.md`, `PRIVACY.md`, and `CREDITS.md`.
- Expanded technical research paper `papers/cellular-data-hotspot-optimization.md` with comparative performance matrix and vendor skin NetPolicy evaluation.
- One-line direct curl execution commands across every fix and diagnostic guide in `linux/`, `android/`, and `network/`.
- Pre-reboot `/boot` validation scripts `linux/arch/scripts/pre-reboot-health-check.sh` and `pre-reboot-health-check.fish`.
- Installation guide `linux/scripts/install-legacy-launcher.md` for Minecraft Legacy Launcher with desktop entry registration and one-line curl installer.
- Termux automated setup scripts `android/termux/scripts/install-claude-code-termux.sh` and `install-claude-code-termux.fish` for Claude Code v2.1.47 compatibility.
- Termux Google Cloud SDK setup scripts `android/termux/scripts/setup-gcloud-termux.sh` and `setup-gcloud-termux.fish` with automatic PATH, component overrides, and shell aliases.
- Quick Execution Hub table index in `README.md` and regional category index hubs (`linux/README.md`, `android/README.md`, `network/README.md`).
- Technical research paper `papers/cellular-data-hotspot-optimization.md` analyzing Android cellular traffic reduction, hotspot mutual exclusion with system Data Saver, and granular background socket controls.
- Technical guide `android/cellular-data-notification-saver.md` with complete ADB manual commands, AppOps parameters, and NetPolicy configurations.
- Automation script `android/scripts/manage-shopping-traffic.sh` (POSIX/Bash) to pause and resume non-essential app notifications and background data.
- Automation script `android/scripts/manage-shopping-traffic.fish` (Fish shell) with persistent command execution and syntax verification.
- Termux mobile fix hub `android/termux-scripts/` with self-contained on-device scripts for traffic control, storage auditing, and cache trimming.
- Community and repository governance standards: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `SECURITY.md`.

### Changed
- Updated `linux/arch/scripts/manage-sudo-user.sh` and `manage-sudo-user.fish` to query `/dev/tty` for interactive password input when executed through piped curl streams.
- Replaced non-standard typographical dashes and emoji symbols across documentation files to satisfy strict human writing standards.
- Added BigBasket, JioMart, Nykaa, Snapdeal, and Tata CLiQ to the shopping traffic restriction targets.
- Removed the `## 5. Engineering and Writing Standards` section from `scripts/update-readme.py`; `README.md` regenerated from the updated template.
- Rewrote stock wording in `developer-tools/README.md`, `papers/git-tulkun-visualization.md`, `android/README.md`, `android/storage-optimization.md`, and the Flash provider guide to state project facts directly. Replaced en dashes in numeric ranges and heading separators in the Flash provider guide with hyphens and colons.
- Added the Flash provider guide to `ai-providers/README.md` and marked its quota/model data as a dated research snapshot requiring provider-side verification.

### Fixed
- Made Android tethering offload writes optional in the shopping traffic scripts. Devices that deny `WRITE_SECURE_SETTINGS` now receive a warning while per-app restrictions continue.
- Fixed `pm list packages` output carrying CR line endings so exact-match package checks silently failed. Package matching now strips CR before comparison in `manage-shopping-traffic.sh`, `manage-shopping-traffic.fish`, `termux-manage-shopping-traffic.sh`, `termux-manage-shopping-traffic.fish`, and `audit-android-storage.sh`.
- Fixed `hotspot-background-traffic-control.sh` and `termux-hotspot-traffic-control.sh` keeping the trailing CR on package names parsed from `pm list packages`, which made every downstream `dumpsys`/`appops`/`netpolicy` call fail silently for every third-party app.
- Fixed Fish scripts passing `uid:NNN` (the whole regex match) to `netpolicy` and `iptables` instead of the numeric UID. All Fish UID extractions now use `string match -rg`.
- Fixed Fish coordinate parsing in `manage-shopping-traffic.fish` (`automate-ui`) reading wrong capture group indices after switching to `-rg`; taps now target the correct element bounds.
- Fixed `termux-audit-storage.sh` and `termux-audit-storage.fish` deleting `"$TMPDIR"/*` when `TMPDIR` is unset, which crashed bash under `set -u` and could expand to `rm -rf /*` in fish. Both now resolve a safe default and use `find -mindepth 1 -xdev -delete` with an explicit guard against unsafe paths.
- Added Magisk/KernelSU boot hooks at `/data/adb/service.d/devsubstrate-shopping-restrictions.sh` and `/data/adb/service.d/devsubstrate-hotspot-restrictions.sh` so rooted devices re-apply AppOps modes, standby buckets, NetPolicy blacklists and `iptables`/`ip6tables` DROP rules after every reboot. The `resume`/`revert` actions remove the hook. On non-rooted devices the restrictions persist natively via the Android settings/AppOps/NetPolicy stores.
- Hardened the `/etc/sudoers` edit in `manage-sudo-user.sh` and `manage-sudo-user.fish` with a timestamped backup and `visudo -cf` validation; the backup is restored automatically when validation fails.
- Fixed AppOps `SecurityException: uid 2000 does not have android.permission.MANAGE_APP_OPS_MODES` on ColorOS, OxygenOS, Realme UI, MIUI, and HyperOS with the permission monitor enabled. Scripts now detect the permission-denied output, show the OEM-specific toggle name, and continue with the remaining restrictions (standby bucket and NetPolicy blacklist) without aborting. The exit code is non-zero when AppOps is refused.

## [0.2.0] - 2026-11-08

### Added
- Troubleshooting guide `linux/ssh/gcloud-ssh-x11-clipboard-fix.md` resolving remote clipboard image pasting errors across Google Cloud Shell SSH sessions.
- Automated table index generator `scripts/update-readme.py` and GitHub Action `.github/workflows/update-readme.yml`.
- Technical research paper `papers/paper-mono-typography.md` evaluating Paper Mono optical geometry, coding ligatures, and terminal configuration.
- Markdown table formatting across all sections of `README.md`.

## [0.1.0] - 2026-11-08

### Added
- Initial project structure created from `fixes` transformation into `devSubstrate`.
- Core technical research papers in `papers/`:
  - `groq-wse-inference.md` (Groq LPU architecture and deterministic scheduling)
  - `cerebras-wse-inference.md` (Cerebras WSE-3 wafer-scale inference benchmarks)
  - `google-ai-studio-gemini.md` (Gemini million-token context windows and REST API)
  - `apinex-gateway-proxy.md` (Multi-model proxy routing and security trade-offs)
  - `agy-autonomous-agent.md` (Google Antigravity agent runtime architecture)
  - `opencode-codex-agents.md` (Terminal-native agents vs cloud code models)
  - `git-tulkun-visualization.md` (Procedural pixel art and GitHub Actions telemetry)
  - `react-bits-ui.md` (Zero-dependency React component library architecture)
  - `efecto-ai-canvas.md` (AI-native collaborative design canvas with MCP support)
  - `ascii-rendering-engines.md` (Luminance quantization in ascii.rest and Asciify)
  - `asciicore-figma-dithering.md` (VGA matrix dithering within Figma)
- Resource implementation manuals: `ai-providers/README.md`, `developer-tools/README.md`, and `creative-ascii-design/README.md`.
- Preserved system diagnostics for Linux, Android, Network, and Windows platforms.
