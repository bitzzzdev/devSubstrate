#!/usr/bin/env python3
"""
Generate and update README.md index for devSubstrate repository.
All resource entries link directly to local research papers or fix markdown files.
"""

from pathlib import Path
import re

REPO_ROOT = Path(__file__).resolve().parent.parent

def extract_title(path: Path) -> str:
    """Extract the first H1 header from markdown file."""
    try:
        text = path.read_text(encoding="utf-8")
        match = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
        if match:
            return match.group(1).strip()
    except Exception:
        pass
    return path.stem.replace("-", " ").title()

def main():
    readme_path = REPO_ROOT / "README.md"
    
    content = """# DevSubstrate: Engineering Research, Technical Papers, and System Notes

Author and Maintainer: Dev Borah (bitzzdev)  
Repository: `devSubstrate`  
Focus: Systems engineering, hardware-accelerated AI inference, developer agents, and graphics architectures.

All entries link directly to internal research papers and verified system fix files.

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
│   └── paper-mono-typography.md         Paper Mono font anatomy, ligatures, and duospacing
├── ai-providers/              API endpoint documentation and curl integration
├── developer-tools/           Autonomous assistants, terminal utilities, and setup notes
├── creative-ascii-design/     Frontend components, ASCII engines, and typography guides
├── android/                   Device performance, storage recovery, and Termux fixes
├── linux/                     Arch Linux health checks, UKI boot, and driver repairs
├── network/                   Bandwidth reduction and Qualcomm Wi-Fi stability fixes
├── windows/                   Diagnostics and operating system troubleshooting
└── cross-platform/            Shared cross-environment scripts and tools
```

---

## 1. Technical Research Papers

Evaluations of hardware architectures, model inference runtimes, agent systems, and rendering pipelines:

### AI Inference and API Gateways
- [Groq LPU Inference Architecture](papers/groq-inference-analysis.md): SRAM layout, deterministic instruction scheduling, and token latency.
- [Cerebras Wafer-Scale Engine](papers/cerebras-wse-inference.md): Wafer-scale chip topology, 900,000 AI cores, and high token throughput.
- [Google AI Studio and Gemini Architecture](papers/google-ai-studio-gemini.md): Long context windows, REST API usage, and structured JSON schemas.
- [APInex Gateway and Third-Party Proxy Security](papers/apinex-gateway-proxy.md): Multi-model routing mechanics and API security trade-offs.

### Developer Agents and Coding Tooling
- [Google Antigravity (AGY) Agent Architecture](papers/agy-autonomous-agent.md): Orchestration runtime, subagent delegation, and artifact systems.
- [Terminal-Native Agents: OpenCode and Codex](papers/opencode-codex-agents.md): Comparing shell-integrated agents with cloud model generators.
- [Git-Tulkun Procedural Visualization](papers/git-tulkun-visualization.md): Logarithmic activity scaling and automated GitHub Actions workflows.

### Creative, ASCII, and Typography Systems
- [React Bits Modular UI Architecture](papers/react-bits-ui.md): Micro-interactions, Tailwind integration, and bundle optimization.
- [Efecto AI-Collaborative Canvas](papers/efecto-ai-canvas.md): Real-time design canvas, WebGL shaders, and MCP tool protocols.
- [ASCII Rendering Engines Analysis](papers/ascii-rendering-engines.md): Luminance quantization in ascii.rest, ASCII Magic, and Asciify.
- [Vector Dithering with Asciicore](papers/asciicore-figma-dithering.md): Bayer matrices and Floyd-Steinberg dithering within Figma.
- [Paper Mono Typeface Anatomy](papers/paper-mono-typography.md): Coding ligatures, duospacing, and terminal ergonomics.

---

## 2. Resource Implementation Manuals

Pragmatic developer documentation with command-line steps, configuration files, and API endpoints:
- [AI API Providers Manual](ai-providers/README.md): Step-by-step API key generation, endpoints, and authentication headers.
- [Developer Tools and Assistants Manual](developer-tools/README.md): Installation and command lines for AGY, OpenCode, and git-tulkun.
- [Creative, ASCII, and Design Manual](creative-ascii-design/README.md): Feature breakdowns and setup notes for web generators and Figma plugins.

---

## 3. Systems Engineering and Verified Fixes

Technical troubleshooting procedures, diagnostics, and recovery scripts:

### Linux Systems and Boot Configurations
- [Arch Linux Pre-Reboot Health Check](linux/arch/pre-reboot-health-check.md): Kernel verification, systemd checks, and bootloader integrity.
- [Unified Kernel Image (UKI) QCA9377 Wi-Fi Fix](linux/arch/uki-qca9377-wifi-fix.md): Firmware module parameters and power management overrides.
- [VLC H.264 Codec Playback Fix](linux/arch/vlc-h264-codec-fix.md): Hardware decoding and VAAPI configuration.
- [Create Sudo User Guide](linux/arch/create-sudo-user.md): Secure user creation and wheel group privilege delegation.
- [Legacy Launcher Installation Script](linux/scripts/install-legacy-launcher.sh): Automated shell script for client installation.
- [Linux Troubleshooting Hub](linux/README.md): Index of distribution-specific maintenance guides.

### Android Device Optimization and Termux
- [Claude Code CLI on Android via Termux](android/termux/claude-code-cli-workaround.md): Node environment, termux-exec, and path workarounds.
- [Realme C11 (RMX3231) Optimization](android/realme-c11-rmx3231-optimization.md): Background process control, RAM reclaim, and debloating.
- [Storage Space Recovery Guide](android/storage-optimization.md): Deep cache cleaning, orphan file removal, and ADB storage inspection.
- [Android Diagnostics Hub](android/README.md): Platform-level troubleshooting overview.

### Network and Connectivity
- [QCA9377 Wi-Fi Automated Fix](network/wifi/qca9377-auto-fix.md): Driver reload and systemd service creation.
- [QCA9377 Hotspot Disconnect Fix](network/wifi/qca9377-hotspot-disconnect-fix.md): Packet drop mitigation and power save disabling.
- [Linux & Android Data Consumption Reduction](network/linux-android-internet-usage-optimization.md): Metered connection rules and daemon traffic limits.
- [Network Troubleshooting Hub](network/README.md): Wi-Fi and mobile interface maintenance index.

### Windows and Cross-Platform Tools
- [Windows Diagnostic Procedures](windows/README.md): DISM checks, SFC repairs, and driver conflict resolution.
- [Cross-Platform Utilities](cross-platform/README.md): Shared maintenance patterns across operating systems.

---

## Engineering and Writing Standards

- Every paper documents observed behavior, verified endpoints, and architectural mechanisms.
- All prose follows strict human writing standards: no promotional filler, no em dashes, and no emoji.
- Configurations must include exact file locations, parameter types, and rollback steps.
"""
    readme_path.write_text(content, encoding="utf-8")
    print(f"Updated {readme_path}")

if __name__ == "__main__":
    main()
