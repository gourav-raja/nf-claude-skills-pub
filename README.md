# noon-claude-skills

Official Claude Code plugin marketplace for Noon Food engineering.

## Installation

### Prerequisites
- [Claude Code](https://claude.ai/code) installed and logged in
- `git` installed (comes with Xcode Command Line Tools on Mac)

### Step 1 — Fix GitHub cloning (one-time, do this first)

Claude Code clones plugins from GitHub. If your machine uses SSH for git (most do), you need to tell it to use HTTPS instead:

```bash
git config --global url."https://github.com/".insteadOf "git@github.com:"
```

> **Why?** Claude Code's plugin installer doesn't use your SSH keys. Without this, you'll get `Permission denied (publickey)` errors.

### Step 2 — Register the marketplace

```bash
claude plugin marketplace add gourav-raja/nf-claude-skills-pub
```

Expected output: `✔ Successfully added marketplace: nf-claude-skills-pub`

### Step 3 — Install plugins

```bash
claude plugin install nf-analyst@nf-claude-skills-pub
claude plugin install figma-events@nf-claude-skills-pub
```

Expected output for each: `✔ Successfully installed plugin: <name> (scope: user)`

### Done

Open a new Claude Code session. Type `/nf-analyst` or `/figma-events` to verify.

---

### One-liner (does all 3 steps)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gourav-raja/nf-claude-skills-pub/main/install.sh)
```

---

## Updating plugins

```bash
claude plugin update nf-analyst@nf-claude-skills-pub
claude plugin update figma-events@nf-claude-skills-pub
```

---

## Troubleshooting

**`Permission denied (publickey)` during install**
→ You skipped Step 1. Run:
```bash
git config --global url."https://github.com/".insteadOf "git@github.com:"
```
Then retry the install.

**`Failed to add marketplace: Marketplace name cannot contain spaces`**
→ The `marketplace.json` in the repo has a naming issue. Ping the repo owner.

**`This plugin uses a source type your Claude Code version does not support`**
→ Update Claude Code:
```bash
npm install -g @anthropic-ai/claude-code
```

**`Plugin "nf-analyst" not found` when updating**
→ Always include the marketplace name when updating:
```bash
claude plugin update nf-analyst@nf-claude-skills-pub   # ✓ correct
claude plugin update nf-analyst                         # ✗ won't work
```

**Plugin installed but skill not showing up**
→ Restart Claude Code. Some plugin changes require a fresh session.

---

## Available skills

| Command | What it does |
|---|---|
| `/nf-analyst <question>` | Converts plain-English questions into BigQuery SQL using noon food's curated context library |
| `/figma-events <figma_url>` | Generates a Noon Food analytics event spec (YAML) from a Figma screen URL |

---

## Admin setup

To pre-register this marketplace for all org members via managed settings:

```json
{
  "extraKnownMarketplaces": {
    "nf-claude-skills-pub": {
      "source": {
        "source": "github",
        "repo": "gourav-raja/nf-claude-skills-pub"
      },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "nf-analyst@nf-claude-skills-pub": true,
    "figma-events@nf-claude-skills-pub": true
  }
}
```

With this in managed settings, devs only need to run Steps 1 and 3 — the marketplace is pre-registered.

---

## Contributing a plugin

1. Create `plugins/<name>/skills/<name>/SKILL.md`
2. Add `plugins/<name>/.claude-plugin/plugin.json`
3. Register it in `.claude-plugin/marketplace.json`
4. Push — devs get it on next `claude plugin update`
