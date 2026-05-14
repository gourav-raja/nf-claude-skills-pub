#!/usr/bin/env bash
set -euo pipefail

MARKETPLACE="nf-claude-skills-pub"
REPO="gourav-raja/nf-claude-skills-pub"

PLUGINS=(
  "nf-analyst"
  "figma-events"
)

echo "→ Configuring git to use HTTPS for GitHub..."
git config --global url."https://github.com/".insteadOf "git@github.com:"

echo "→ Adding marketplace: $MARKETPLACE"
claude plugin marketplace add "$REPO"

for plugin in "${PLUGINS[@]}"; do
  echo "→ Installing plugin: $plugin"
  claude plugin install "$plugin@$MARKETPLACE"
done

echo "✔ Done. Skills available in your next Claude Code session."
