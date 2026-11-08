# DevSubstrate: Engineering Research, Technical Papers, and System Notes

Author and Maintainer: Dev Borah (bitzzdev)  
Repository: `devSubstrate`  
Focus: Systems engineering, hardware-accelerated AI inference, developer agents, and graphics architectures.

---

## Repository Structure

```text
├── papers/                    In-depth research papers for tools and architectures
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
├── ai-providers/              Quick-start guides, curl snippets, and API endpoints
├── developer-tools/           Autonomous assistants, terminal utilities, and setup notes
├── creative-ascii-design/     Frontend libraries, ASCII generators, and design plugins
├── android/                   Device performance, storage reclamation, and Termux setup
├── linux/                     Arch Linux health checks, UKI kernel boot, and Wi-Fi drivers
├── network/                   Bandwidth reduction and Qualcomm Wi-Fi stability fixes
├── windows/                   Diagnostics and operating system troubleshooting
└── cross-platform/            Shared cross-environment scripts and tools
```

---

## 1. Technical Research Papers

Formal technical research papers detailing architecture, algorithms, and benchmark performance:

### AI Inference and API Gateways
- [Groq LPU Inference Architecture](papers/groq-inference-analysis.md): SRAM layout, deterministic instruction scheduling, and token latency.
- [Cerebras Wafer-Scale Engine](papers/cerebras-wse-inference.md): Wafer-scale chip topology, 900,000 AI cores, and high token throughput.
- [Google AI Studio & Gemini Architecture](papers/google-ai-studio-gemini.md): Long context windows, REST API usage, and structured JSON schemas.
- [APInex Gateway and Third-Party Proxy Security](papers/apinex-gateway-proxy.md): Multi-model routing mechanics and API security trade-offs.

### Developer Agents and Tooling
- [Google Antigravity (AGY) Agent Architecture](papers/agy-autonomous-agent.md): Orchestration runtime, subagent delegation, and artifact systems.
- [Terminal-Native Agents: OpenCode and Codex](papers/opencode-codex-agents.md): Comparing shell-integrated agents with cloud model generators.
- [Git-Tulkun Procedural Visualization](papers/git-tulkun-visualization.md): Logarithmic activity scaling and automated GitHub Actions workflows.

### Creative, ASCII, and Frontend Systems
- [React Bits Modular UI Architecture](papers/react-bits-ui.md): Micro-interactions, Tailwind integration, and bundle optimization.
- [Efecto AI-Collaborative Canvas](papers/efecto-ai-canvas.md): Real-time design canvas, WebGL shaders, and MCP tool protocols.
- [ASCII Rendering Engines Analysis](papers/ascii-rendering-engines.md): Luminance quantization in ascii.rest, ASCII Magic, and Asciify.
- [Vector Dithering with Asciicore](papers/asciicore-figma-dithering.md): Bayer matrices and Floyd-Steinberg dithering within Figma.
- [Paper Mono Typeface Anatomy](papers/paper-mono-typography.md): Coding ligatures, duospacing, and terminal ergonomics.

---

## 2. Quick Integration Reference Manuals

Pragmatic developer documentation with ready-to-run code snippets:
- [AI API Providers Guide](ai-providers/README.md): Step-by-step API key generation, endpoints, and authentication headers.
- [Developer Tools Guide](developer-tools/README.md): Installation and command lines for AGY, OpenCode, and git-tulkun.
- [Creative and ASCII Design Guide](creative-ascii-design/README.md): Quick links and setup notes for web generators and Figma plugins.

---

## 3. Systems Engineering and Hardware Fixes

Battle-tested diagnostic guides and scripts for physical hardware and operating systems:
- [Linux Systems](linux/README.md): Arch Linux maintenance, unified kernel images (UKI), and Qualcomm QCA9377 driver fixes.
- [Android Devices](android/README.md): Internal storage recovery, memory management, and Termux CLI workarounds.
- [Network Infrastructure](network/README.md): Wi-Fi hotspot stability and mobile data consumption caps.
- [Cross-Platform](cross-platform/README.md): Multi-OS command snippets and synchronization routines.
- [Windows Systems](windows/README.md): System repair and registry tuning procedures.

---

## Engineering and Writing Standards

- Every paper documents observed behavior, verified endpoints, and architectural mechanisms.
- All prose follows strict human writing standards: no promotional filler, no em dashes, and no emoji.
- Configurations must include exact file locations, parameter types, and rollback steps.
