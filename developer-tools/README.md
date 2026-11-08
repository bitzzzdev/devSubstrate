# Developer Tools and Coding Assistants

Reference guides for autonomous coding assistants, CLI workflows, and terminal-native developer tooling.

## Quick Index

| Tool | Focus Area | Interface | Link / Reference |
| --- | --- | --- | --- |
| AGY (Google Antigravity) | Agentic coding CLI, workflows, IDE integration | CLI (`agy`) | Built-in AGY environment |
| OpenCode | Open-source terminal agent and coding assistant | Terminal CLI | [github.com/opencode-ai](https://github.com/opencode-ai) |
| OpenAI Codex / Coding Models | Code generation engines and agent backends | API / Editor extensions | [platform.openai.com](https://platform.openai.com/) |
| git-tulkun | GitHub contribution activity visualizer (pixel art) | GitHub Action | [github.com/PramudithaN/git-tulkun](https://github.com/PramudithaN/git-tulkun) |

---

## 1. Google Antigravity (AGY)

AGY is an agentic coding environment built for pair programming, repository inspection, background task execution, and codebase edits.

### Key Capabilities
- Terminal CLI (`agy`) with multi-workspace support.
- Specialized subagents for research, browser automation, and code writing.
- Skill and plugin architecture stored locally in `~/.gemini/antigravity-cli/skills/`.
- File inspection, command execution, and structured artifacts.

### Common CLI Invocations
```bash
# Check version and active configuration
agy --version

# Launch interactive session inside any repository
cd /path/to/project
agy
```

---

## 2. OpenCode

OpenCode provides an open-source terminal interface for autonomous AI programming, acting as a local agent in your git workspace.

### Key Features
- Terminal-first workflow without requiring heavy IDE plugins.
- Works directly with local git state, diffs, and project files.
- Supports switching backend LLM providers (Anthropic, OpenAI, local Ollama, Groq).

---

## 3. OpenAI Codex and Code Models

Codex pioneered large-scale code synthesis, powering tools like GitHub Copilot and successor frontier models (o1, o3-mini, GPT-4o) tuned for code reasoning.

### Key Use Cases
- Automated refactoring and test generation.
- Schema translation and API client drafting.
- Shell script debugging and syntax translation across programming languages.

---

## 4. git-tulkun

`git-tulkun` is an automated GitHub Action created by Pramuditha Nadun that generates a dynamic, looping pixel-art Tulkun whale for your GitHub profile README.

### Project Link
- Repository: [github.com/PramudithaN/git-tulkun](https://github.com/PramudithaN/git-tulkun)
- Live preview: [pramudithan.github.io/git-tulkun](https://pramudithan.github.io/git-tulkun)

### How It Works
- **Growth:** The Tulkun grows from a calf to an armored adult based on your commit activity.
- **Coloring:** The color palette is drawn from the primary languages across your repositories.
- **Workflow:** Runs daily via GitHub Actions and commits output files to an orphan branch without polluting your main git log.

### GitHub Actions Setup
Add a workflow file in `.github/workflows/tulkun.yml`:

```yaml
name: Generate Git Tulkun
on:
  schedule:
    - cron: "0 0 * * *"
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: PramudithaN/git-tulkun@main
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```
