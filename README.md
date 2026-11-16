# DevSubstrate: Engineering Research, Technical Papers, and System Notes

Author and Maintainer: Dev Borah (bitzzdev)  
Repository: `devSubstrate`  
Focus: Systems engineering, hardware-accelerated AI inference, developer agents, and graphics architectures.

All entries in the tables below link directly to internal research papers, verified system fix files, and direct curl one-liners.

---

## Repository Tree

```text
├── papers/                    In-depth technical research papers
│   ├── groq-inference-analysis.md       Groq LPU speed, SRAM design, and API limits
│   ├── cerebras-wse-inference.md        Cerebras Wafer-Scale Engine and token throughput
│   ├── google-ai-studio-gemini.md       Gemini million-token context and function calling
│   ├── apinex-gateway-proxy.md          Multi-model API proxying and security boundaries
│   ├── agy-autonomous-agent.md          Google Antigravity CLI agent runtime architecture
│   ├── opencode-codex-agents.md         Terminal-native coding agents vs cloud code models
│   ├── git-tulkun-visualization.md      Procedural pixel art and GitHub Actions automation
│   ├── react-bits-ui.md                 Zero-dependency React components and animation
│   ├── efecto-ai-canvas.md              AI-native design canvas and MCP agent integration
│   ├── ascii-rendering-engines.md       ascii.rest, ASCII Magic, and Asciify algorithms
│   ├── asciicore-figma-dithering.md     VGA matrix dithering inside Figma
│   ├── paper-mono-typography.md         Paper Mono font anatomy, ligatures, and duospacing
│   └── cellular-data-hotspot-optimization.md Android cellular traffic control and hotspot preservation
├── ai-providers/              API endpoint documentation and curl integration
├── developer-tools/           Autonomous assistants, terminal utilities, and setup notes
├── creative-ascii-design/     Frontend components, ASCII engines, and typography guides
├── android/                   Device performance, storage recovery, and Termux fixes
├── linux/                     Arch Linux health checks, UKI boot, SSH, and driver repairs
├── network/                   Bandwidth reduction and Qualcomm Wi-Fi stability fixes
├── windows/                   Diagnostics and operating system troubleshooting
└── cross-platform/            Shared cross-environment scripts and tools
```

---

## 1. Technical Research Papers

Evaluations of hardware architectures, model inference runtimes, agent systems, and rendering pipelines.

### AI Inference and API Gateways

| Topic / System | Research Paper | Focus Area |
| --- | --- | --- |
| Groq LPU | [Groq LPU Inference Architecture](papers/groq-inference-analysis.md) | SRAM layout, deterministic instruction scheduling, and token latency |
| Cerebras WSE-3 | [Cerebras Wafer-Scale Engine](papers/cerebras-wse-inference.md) | Wafer-scale chip topology, 900,000 AI cores, and high token throughput |
| Google AI Studio | [Google AI Studio and Gemini Architecture](papers/google-ai-studio-gemini.md) | Long context windows, REST API usage, and structured JSON schemas |
| APInex Gateway | [APInex Gateway and Third-Party Proxy Security](papers/apinex-gateway-proxy.md) | Multi-model routing mechanics and API security trade-offs |

### Developer Agents and Coding Tools

| Topic / System | Research Paper | Focus Area |
| --- | --- | --- |
| Google Antigravity | [Google Antigravity (AGY) Agent Architecture](papers/agy-autonomous-agent.md) | Orchestration runtime, subagent delegation, and artifact systems |
| OpenCode & Codex | [Terminal-Native Agents: OpenCode and Codex](papers/opencode-codex-agents.md) | Comparing shell-integrated agents with cloud model generators |
| Git-Tulkun | [Git-Tulkun Procedural Visualization](papers/git-tulkun-visualization.md) | Logarithmic activity scaling and automated GitHub Actions workflows |

### Creative, ASCII, and Typography Systems

| Topic / System | Research Paper | Focus Area |
| --- | --- | --- |
| React Bits | [React Bits Modular UI Architecture](papers/react-bits-ui.md) | Micro-interactions, Tailwind integration, and bundle optimization |
| Efecto | [Efecto AI-Collaborative Canvas](papers/efecto-ai-canvas.md) | Real-time design canvas, WebGL shaders, and MCP tool protocols |
| ASCII Web Engines | [ASCII Rendering Engines Analysis](papers/ascii-rendering-engines.md) | Luminance quantization in ascii.rest, ASCII Magic, and Asciify |
| Asciicore Plugin | [Vector Dithering with Asciicore](papers/asciicore-figma-dithering.md) | Bayer matrices and Floyd-Steinberg dithering within Figma |
| Paper Mono | [Paper Mono Typeface Anatomy](papers/paper-mono-typography.md) | Coding ligatures, duospacing, and terminal ergonomics |

### Systems Engineering and Mobile Architectures

| Topic / System | Research Paper | Focus Area |
| --- | --- | --- |
| Android Hotspot & Data | [Cellular Data & Hotspot Optimization](papers/cellular-data-hotspot-optimization.md) | Suppressing non-essential retail apps, NetPolicy blacklists, and tether offload |

---

## 2. Resource Implementation Manuals

Pragmatic developer documentation with command-line steps, configuration files, and API endpoints.

| Manual | Direct Link | Content Summary |
| --- | --- | --- |
| AI API Providers | [AI API Providers Guide](ai-providers/README.md) | Step-by-step API key generation, endpoints, and authentication headers |
| Developer Tools | [Developer Tools and Assistants Guide](developer-tools/README.md) | Installation and command lines for AGY, OpenCode, and git-tulkun |
| Creative & Design | [Creative, ASCII, and Design Guide](creative-ascii-design/README.md) | Feature breakdowns and setup notes for web generators and Figma plugins |

---

## 3. Systems Engineering and Verified Fixes

Technical troubleshooting procedures, diagnostics, and recovery scripts.

### Linux Systems and Boot Configurations

| Component | Verified Fix / Procedure | Target Issue |
| --- | --- | --- |
| Arch Linux Maintenance | [Arch Linux Pre-Reboot Health Check](linux/arch/pre-reboot-health-check.md) | Kernel verification, systemd checks, and bootloader integrity |
| Qualcomm Wi-Fi / UKI | [Unified Kernel Image QCA9377 Wi-Fi Fix](linux/arch/uki-qca9377-wifi-fix.md) | Firmware module parameters and power management overrides |
| Video Decoding | [VLC H.264 Codec Playback Fix](linux/arch/vlc-h264-codec-fix.md) | Hardware decoding and VAAPI configuration |
| Cloud Shell & SSH X11 | [Cloud Shell SSH X11 Clipboard Fix](linux/ssh/gcloud-ssh-x11-clipboard-fix.md) | Remote clipboard image paste, X11 forwarding, Fish/Bash aliases |
| User Privileges | [Create Sudo User Guide](linux/arch/create-sudo-user.md) | Secure user creation and wheel group privilege delegation |
| Launcher Script | [Legacy Launcher Installation Guide](linux/scripts/install-legacy-launcher.md) | Automated shell script for client installation |
| Linux Overview | [Linux Troubleshooting Hub](linux/README.md) | Index of distribution-specific maintenance guides |

### Android Device Optimization and Termux

| Device / Tool | Verified Fix / Procedure | Target Issue |
| --- | --- | --- |
| Claude Code on Android | [Claude Code CLI in Termux](android/termux/claude-code-cli-workaround.md) | Node environment, termux-exec, and path workarounds |
| Google Cloud CLI on Android | [Google Cloud CLI on Termux](android/termux/gcloud-cli-termux-workaround.md) | Bionic libc compatibility, component overrides, and shell aliases |
| Realme C11 (RMX3231) | [Realme C11 Optimization Guide](android/realme-c11-rmx3231-optimization.md) | Background process control, RAM reclaim, and debloating |
| Storage Maintenance | [Storage Space Recovery Guide](android/storage-optimization.md) | Deep cache cleaning, orphan file removal, and ADB storage inspection |
| Selective Data Control | [Cellular Traffic & Notification Saver](android/cellular-data-notification-saver.md) | Automation scripts to pause shopping traffic while keeping hotspot and messaging |
| Background Data Automation | [Accessibility Service & UI Traversal](android/accessibility-service/README.md) | Native settings traversal service to toggle background data across OEM skins |
| On-Device Termux Scripts | [Termux Mobile Fix Hub](android/termux-scripts/README.md) | Self-contained on-device scripts with execution audits and fallback modes |
| Android Overview | [Android Diagnostics Hub](android/README.md) | Platform-level troubleshooting overview |

### Network and Connectivity

| Protocol / Interface | Verified Fix / Procedure | Target Issue |
| --- | --- | --- |
| QCA9377 Service | [QCA9377 Wi-Fi Automated Fix](network/wifi/qca9377-auto-fix.md) | Driver reload and systemd service creation |
| Mobile Hotspot | [QCA9377 Hotspot Disconnect Fix](network/wifi/qca9377-hotspot-disconnect-fix.md) | Packet drop mitigation and power save disabling |
| Data Metering | [Linux & Android Data Consumption Reduction](network/linux-android-internet-usage-optimization.md) | Metered connection rules and daemon traffic limits |
| Network Overview | [Network Troubleshooting Hub](network/README.md) | Wi-Fi and mobile interface maintenance index |

### Windows and Cross-Platform Tools

| Environment | Verified Fix / Procedure | Target Issue |
| --- | --- | --- |
| Windows 10/11 | [Windows Diagnostic Procedures](windows/README.md) | DISM checks, SFC repairs, and driver conflict resolution |
| Multi-Platform | [Cross-Platform Utilities](cross-platform/README.md) | Shared maintenance patterns across operating systems |

---

## 4. Quick Execution Hub (One-Line curl Commands)

Run any fix directly without cloning the repository. Every script supports status checks, applying fixes, and safe reversion where applicable.

### Linux and Boot Repairs

| Operation | Direct One-Line curl Command |
| --- | --- |
| Pre-Reboot Health Check | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/pre-reboot-health-check.sh \| bash` |
| Pre-Reboot Health Check (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/pre-reboot-health-check.sh \| bash` |
| Apply UKI Wi-Fi Fix | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/uki-qca9377-fix.sh \| sudo bash -s -- apply` |
| Apply UKI Wi-Fi Fix (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/uki-qca9377-fix.sh \| sudo bash -s -- apply` |
| Revert UKI Wi-Fi Fix | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/uki-qca9377-fix.sh \| sudo bash -s -- revert` |
| Revert UKI Wi-Fi Fix (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/uki-qca9377-fix.sh \| sudo bash -s -- revert` |
| Apply VLC H.264 Plugin | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh \| sudo bash -s -- apply` |
| Apply VLC H.264 Plugin (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh \| sudo bash -s -- apply` |
| Revert VLC H.264 Plugin | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh \| sudo bash -s -- revert` |
| Revert VLC H.264 Plugin (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/vlc-ffmpeg-plugin-fix.sh \| sudo bash -s -- revert` |
| Create Sudo User | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/arch/scripts/manage-sudo-user.sh \| sudo bash -s -- create <user>` |
| Create Sudo User (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/arch/scripts/manage-sudo-user.sh \| sudo bash -s -- create <user>` |
| Apply SSH X11 Persistence | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/ssh/scripts/configure-ssh-x11-forwarding.sh \| bash -s -- apply` |
| Apply SSH X11 Persistence (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/ssh/scripts/configure-ssh-x11-forwarding.sh \| bash -s -- apply` |
| Revert SSH X11 Persistence | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/ssh/scripts/configure-ssh-x11-forwarding.sh \| bash -s -- revert` |
| Revert SSH X11 Persistence (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/ssh/scripts/configure-ssh-x11-forwarding.sh \| bash -s -- revert` |
| Install Legacy Launcher | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/linux/scripts/install-legacy-launcher.sh \| bash` |
| Install Legacy Launcher (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/linux/scripts/install-legacy-launcher.sh \| bash` |

### Android Diagnostics, Traffic Control, and Termux

| Operation | Direct One-Line curl Command |
| --- | --- |
| Check Root & OEM Unlock (ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- check` |
| Check Root & OEM Unlock (ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- check` |
| Pause Shopping Traffic (ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- pause` |
| Pause Shopping Traffic (ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- pause` |
| Resume Shopping Traffic (ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- resume` |
| Resume Shopping Traffic (ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- resume` |
| UI Automate Data Toggle (ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- automate-ui` |
| UI Automate Data Toggle (ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/manage-shopping-traffic.sh \| bash -s -- automate-ui` |
| Audit Storage (ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/audit-android-storage.sh \| bash -s -- status` |
| Audit Storage (ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/audit-android-storage.sh \| bash -s -- status` |
| Trim Package Caches (ADB) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/scripts/audit-android-storage.sh \| bash -s -- trim` |
| Trim Package Caches (ADB) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/scripts/audit-android-storage.sh \| bash -s -- trim` |
| Termux Root & OEM Check | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux-scripts/termux-manage-shopping-traffic.sh \| bash -s -- check` |
| Termux Root & OEM Check (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux-scripts/termux-manage-shopping-traffic.sh \| bash -s -- check` |
| Termux Shopping Traffic Pause | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux-scripts/termux-manage-shopping-traffic.sh \| bash -s -- pause` |
| Termux Shopping Traffic Pause (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux-scripts/termux-manage-shopping-traffic.sh \| bash -s -- pause` |
| Termux Hotspot Background Saver | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux-scripts/termux-hotspot-traffic-control.sh \| bash -s -- apply` |
| Termux Hotspot Background Saver (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux-scripts/termux-hotspot-traffic-control.sh \| bash -s -- apply` |
| Termux Storage Audit & Trim | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux-scripts/termux-audit-storage.sh \| bash -s -- status` |
| Termux Storage Audit & Trim (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux-scripts/termux-audit-storage.sh \| bash -s -- status` |
| Install Claude Code in Termux | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/install-claude-code-termux.sh \| bash` |
| Install Claude Code in Termux (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/install-claude-code-termux.sh \| bash` |
| Setup Google Cloud SDK in Termux | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/android/termux/scripts/setup-gcloud-termux.sh \| bash -s -- apply` |
| Setup Google Cloud SDK in Termux (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/android/termux/scripts/setup-gcloud-termux.sh \| bash -s -- apply` |

### Network and Connectivity

| Operation | Direct One-Line curl Command |
| --- | --- |
| Disable Wi-Fi Powersave (Apply) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- apply` |
| Disable Wi-Fi Powersave (Apply) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- apply` |
| Restore Wi-Fi Powersave (Revert) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- revert` |
| Restore Wi-Fi Powersave (Revert) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/wifi/scripts/qca9377-powersave-fix.sh \| sudo bash -s -- revert` |
| Hotspot Background Saver (Check) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- check` |
| Hotspot Background Saver (Check) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- check` |
| Hotspot Background Saver (Apply) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- apply` |
| Hotspot Background Saver (Apply) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- apply` |
| Hotspot Background Saver (Revert) | `curl -fsSL https://raw.githubusercontent.com/bitzzdev/devSubstrate/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- revert` |
| Hotspot Background Saver (Revert) (GitLab) | `curl -fsSL https://gitlab.com/bitzzdev/devSubstrate/-/raw/main/network/scripts/hotspot-background-traffic-control.sh \| bash -s -- revert` |

