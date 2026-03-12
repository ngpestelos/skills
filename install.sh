#!/bin/bash
# Sync all ngpestelos/skills into ~/.claude/skills/
# Idempotent — safe to run from dotfiles, cron, or manually.
# Usage: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

installed=0
skipped=0
removed=0

# Install new skills
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"

  if [ -e "$TARGET_DIR/$skill_name" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  ln -s "$skill_dir" "$TARGET_DIR/$skill_name"
  echo "  link  $skill_name"
  installed=$((installed + 1))
done

# Remove stale symlinks pointing into this repo
for link in "$TARGET_DIR"/*/; do
  [ -L "${link%/}" ] || continue
  target="$(readlink "${link%/}")"
  case "$target" in
    "$SKILLS_DIR"/*)
      skill_name="$(basename "$link")"
      if [ ! -d "$SKILLS_DIR/$skill_name" ]; then
        rm "$link"
        echo "  clean $skill_name (removed from repo)"
        removed=$((removed + 1))
      fi
      ;;
  esac
done

echo ""
echo "Done: $installed installed, $skipped unchanged, $removed removed."
