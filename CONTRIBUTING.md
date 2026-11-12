# Contributing to DevSubstrate

Contributions of technical research papers, hardware diagnostics, and systems engineering guides are welcome.

## Standards and Guidelines

### Research Papers (`papers/`)
- Papers must evaluate real systems, architectures, and measurable benchmarks.
- Author credit and evaluation date must be specified in the document header.
- Provide concrete CLI invocations, REST payloads, or reproducible configuration blocks.
- Preserve neutral, human-written technical prose. Follow the rules: no em dashes, no emoji, and no promotional or filler language.

### System Fixes and Scripts (`linux/`, `android/`, `network/`, `windows/`)
- Every troubleshooting guide must include problem diagnosis, step-by-step remediation, verification, and rollback procedures.
- Bash and Fish scripts must be non-destructive by default and provide explicit action switches (e.g. `pause`, `resume`, `status`).
- Always verify shell script syntax before committing (`bash -n script.sh`, `fish -n script.fish`).

### Submitting Changes
1. Fork the repository and create a descriptive branch:
   ```bash
   git checkout -b feature/topic-name
   ```
2. Commit changes with clear, structured messages explaining what was added, what changed, and the rationale.
3. Open a Pull Request on GitHub or a Merge Request on GitLab against branch `main`.
