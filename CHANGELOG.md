# Changelog

All notable changes to the `devSubstrate` repository are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
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

### Fixed
- Made Android tethering offload writes optional in the shopping traffic scripts. Devices that deny `WRITE_SECURE_SETTINGS` now receive a warning while per-app restrictions continue.

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
  - `groq-inference-analysis.md` (Groq LPU architecture and deterministic scheduling)
  - `cerebras-wse-inference.md` (Cerebras WSE-3 wafer-scale inference benchmarks)
  - `google-ai-studio-gemini.md` (Gemini million-token context windows and REST API)
  - `apinex-gateway-proxy.md` (Multi-model proxy routing and security trade-offs)
  - `agy-autonomous-agent.md` (Google Antigravity agent runtime architecture)
  - `opencode-codex-agents.md` (Terminal-native agents vs cloud code models)
  - `git-tulkun-visualization.md` (Procedural pixel art and GitHub Actions telemetry)
  - `react-bits-ui.md` (Zero-dependency React component library architecture)
  - `efecto-ai-canvas.md` (AI-native collaborative design canvas with MCP support)
  - `ascii-rendering-engines.md` (Luminance quantization in ascii.rest and Asciify)
  - `asciicore-figma-dithering.md` (VGA matrix dithering inside Figma)
- Resource implementation manuals: `ai-providers/README.md`, `developer-tools/README.md`, and `creative-ascii-design/README.md`.
- Preserved system diagnostics for Linux, Android, Network, and Windows platforms.
