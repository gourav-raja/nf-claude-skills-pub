# noon-claude-skills

Official internal Claude Code plugin marketplace for Noon food.

## Admin setup

Push this repo to your internal git (e.g. `git.noon.com/platform/noon-claude-skills`).

To enforce the marketplace org-wide via Claude Code enterprise managed settings, add it to your managed settings in the Anthropic Console:

```json
{
  "pluginMarketplaces": [
    "https://git.noon.com/platform/noon-claude-skills/raw/main/marketplace.json"
  ]
}
```

## Developer setup

Run these once on any machine:

```bash
# 1. Allow Claude Code to clone GitHub repos over HTTPS (SSH not required)
git config --global url."https://github.com/".insteadOf "git@github.com:"

# 2. Register the marketplace
claude plugin marketplace add gourav-raja/nf-claude-skills-pub

# 3. Install plugins
claude plugin install nf-analyst@nf-claude-skills-pub
claude plugin install figma-events@nf-claude-skills-pub
```

Or run the install script (does all of the above):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gourav-raja/nf-claude-skills-pub/main/install.sh)
```

Skills are available immediately in any Claude Code session.

## Available skills

| Command | Description |
|---|---|
| `/figma-events <figma_url>` | Generate a Noon Food analytics event spec (YAML) from a Figma screen URL |
| `/brainstorm`, `/tdd`, `/review`, `/implement`, + 10 more | Superpowers — structured development skills (TDD, code review, planning, git workflow) |
| `/nf-analyst <question>` | Text-to-SQL — converts plain-English questions into BigQuery SQL using noon food's curated context library |

## Adding a new skill

1. Create `plugins/<skill-name>/skills/<skill-name>/SKILL.md`
2. Add a `plugins/<skill-name>/manifest.json`
3. Register it in `marketplace.json`
4. Push — developers get it on next `claude plugin update`
