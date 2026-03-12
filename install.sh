#!/bin/bash
# Install all ngpestelos/skills into ~/.claude/skills/
# Usage: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

installed=0
skipped=0

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"

  if [ -e "$TARGET_DIR/$skill_name" ]; then
    echo "  skip  $skill_name (already exists)"
    skipped=$((skipped + 1))
    continue
  fi

  ln -s "$skill_dir" "$TARGET_DIR/$skill_name"
  echo "  link  $skill_name -> $skill_dir"
  installed=$((installed + 1))
done

echo ""
echo "Done: $installed installed, $skipped skipped."
