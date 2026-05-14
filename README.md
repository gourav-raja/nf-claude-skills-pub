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

Add the marketplace once:

```bash
claude plugin marketplace add https://git.noon.com/platform/noon-claude-skills/raw/main/marketplace.json
```

Install the figma-events skill:

```bash
claude plugin install figma-events
```

The skill is now available as `/figma-events` in any Claude Code session.

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
