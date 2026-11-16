# Git-Tulkun: Procedural Generation and GitHub Activity Visualization

Author: Dev Borah (bitzzdev)  
Date: November 2026  
Status: Evaluated

## Abstract

This paper reviews `git-tulkun`, an open-source procedural visualization project created by Pramuditha Nadun. We evaluate its animation mechanics, GitHub GraphQL API data ingestion, logarithmic scaling algorithms, and non-destructive git branch workflows.

## 1. Algorithmic Growth Model

`git-tulkun` visualizes developer commit velocity by generating an animated pixel-art whale that grows dynamically throughout the year.

Mechanics:
- Logarithmic scaling: Contribution counts are mapped across developmental stages (from infant calf to armored bull) using logarithmic curves. This prevents early activity spikes from maxing out stages prematurely while rewarding steady contributions.
- Color extraction: Top language percentages from the user's public repositories determine the color palette of the whale's spine, fins, and body textures.
- Annual lifecycle: A reset triggers automatically on January 1st (or on a rolling 365-day window) to establish yearly milestones.

## 2. GitHub Actions Automation

To maintain a zero-maintenance workflow without polluting repository commit logs, `git-tulkun` uses an orphan branch deployment pattern:

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

Execution steps:
1. Gathers contribution stats via GitHub GraphQL API.
2. Renders GIF frames and composite share cards in headless memory.
3. Force-pushes the rendered assets to an orphan branch (`tulkun-output`), keeping the main git tree clean.

## 3. Findings

`git-tulkun` represents a clean implementation of self-updating repository telemetry, showing how GitHub Actions can automate media generation without manual human intervention.
