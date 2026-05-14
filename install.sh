#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

mkdir -p "$CLAUDE_COMMANDS_DIR"

for file in "$REPO_DIR/commands/"*.md; do
  name="$(basename "$file")"
  target="$CLAUDE_COMMANDS_DIR/$name"

  if [ -L "$target" ]; then
    rm "$target"
  fi

  ln -s "$file" "$target"
  echo "linked: $name → $CLAUDE_COMMANDS_DIR/$name"
done

echo "noon claude skills installed."
