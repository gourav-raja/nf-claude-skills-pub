#!/usr/bin/env bash
set -euo pipefail

MARKETPLACE="nf-claude-skills-pub"

PLUGINS=(
  "nf-analyst"
  "figma-events"
)

for plugin in "${PLUGINS[@]}"; do
  echo "→ Uninstalling plugin: $plugin"
  claude plugin uninstall "$plugin" || true
done

echo "→ Removing marketplace: $MARKETPLACE"
claude plugin marketplace remove "$MARKETPLACE" || true

echo "✔ Done."
