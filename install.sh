#!/bin/bash
# Sync all ngpestelos/skills into ~/.claude/skills/
# Idempotent — safe to run from dotfiles, cron, or manually.
# Usage: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"
CATEGORIES="rails nix claude-code frontend security debugging workflow general"

mkdir -p "$TARGET_DIR"

installed=0
skipped=0
removed=0

# Install new skills from each category directory
for category in $CATEGORIES; do
  category_dir="$SCRIPT_DIR/$category"
  [ -d "$category_dir" ] || continue

  for skill_dir in "$category_dir"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"

    if [ -L "$TARGET_DIR/$skill_name" ]; then
      # Replace broken or outdated symlinks pointing into this repo
      existing_target="$(readlink "$TARGET_DIR/$skill_name")"
      if [ "$existing_target" = "$skill_dir" ]; then
        skipped=$((skipped + 1))
        continue
      fi
      case "$existing_target" in
        "$SCRIPT_DIR"/*)
          rm "$TARGET_DIR/$skill_name"
          ;;
        *)
          skipped=$((skipped + 1))
          continue
          ;;
      esac
    elif [ -e "$TARGET_DIR/$skill_name" ]; then
      skipped=$((skipped + 1))
      continue
    fi

    ln -s "$skill_dir" "$TARGET_DIR/$skill_name"
    echo "  link  $skill_name"
    installed=$((installed + 1))
  done
done

# Remove stale symlinks pointing into this repo
for link in "$TARGET_DIR"/*/; do
  [ -L "${link%/}" ] || continue
  target="$(readlink "${link%/}")"
  case "$target" in
    "$SCRIPT_DIR"/*)
      skill_name="$(basename "$link")"
      # Check if skill still exists in any category
      found=0
      for category in $CATEGORIES; do
        if [ -d "$SCRIPT_DIR/$category/$skill_name" ]; then
          found=1
          break
        fi
      done
      if [ $found -eq 0 ]; then
        rm "$link"
        echo "  clean $skill_name (removed from repo)"
        removed=$((removed + 1))
      fi
      ;;
  esac
done

echo ""
echo "Done: $installed installed, $skipped unchanged, $removed removed."
