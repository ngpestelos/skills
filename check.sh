#!/bin/bash
# Validate skills against Agent Skills spec.
# Usage: ./check.sh [skill-name]   (omit to check all)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE="$SCRIPT_DIR/.claude-plugin/marketplace.json"
errors=0

check_skill() {
  local skill_dir="$1"
  local skill_name="$(basename "$skill_dir")"
  local skill_file="$skill_dir/SKILL.md"

  local errors_before=$errors

  if [ ! -f "$skill_file" ]; then
    echo "FAIL  $skill_name: SKILL.md not found"
    errors=$((errors + 1))
    return
  fi

  # Extract frontmatter (between first and second ---)
  local frontmatter
  frontmatter=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$skill_file")

  # Check name exists and matches directory
  local fm_name
  fm_name=$(echo "$frontmatter" | grep '^name:' | head -1 | sed 's/^name: *//')
  if [ -z "$fm_name" ]; then
    echo "FAIL  $skill_name: missing 'name' in frontmatter"
    errors=$((errors + 1))
  elif [ "$fm_name" != "$skill_name" ]; then
    echo "FAIL  $skill_name: name '$fm_name' does not match directory"
    errors=$((errors + 1))
  fi

  # Check name format: lowercase + hyphens, 1-64 chars, no consecutive hyphens
  if [ -n "$fm_name" ]; then
    if ! echo "$fm_name" | grep -qE '^[a-z][a-z0-9-]{0,63}$'; then
      echo "FAIL  $skill_name: name must be lowercase alphanumeric + hyphens, 1-64 chars"
      errors=$((errors + 1))
    fi
    if echo "$fm_name" | grep -q -- '--'; then
      echo "FAIL  $skill_name: name contains consecutive hyphens"
      errors=$((errors + 1))
    fi
  fi

  # Check description exists and <= 1024 chars
  local desc
  desc=$(echo "$frontmatter" | grep '^description:' | head -1 | sed 's/^description: *//')
  if [ -z "$desc" ]; then
    echo "FAIL  $skill_name: missing 'description' in frontmatter"
    errors=$((errors + 1))
  elif [ ${#desc} -gt 1024 ]; then
    echo "FAIL  $skill_name: description is ${#desc} chars (max 1024)"
    errors=$((errors + 1))
  fi

  # Check body size < 500 lines
  local line_count
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$line_count" -gt 500 ]; then
    echo "FAIL  $skill_name: $line_count lines (max 500)"
    errors=$((errors + 1))
  fi

  # Check version in marketplace.json matches SKILL.md
  local fm_version
  fm_version=$(echo "$frontmatter" | awk '/^  version:/{print $2}' | tr -d '"')
  if [ -z "$fm_version" ]; then
    fm_version=$(echo "$frontmatter" | awk '/^metadata:/{found=1; next} found && /version:/{print $2; exit}' | tr -d '"')
  fi

  if [ -f "$MARKETPLACE" ]; then
    local mp_version
    mp_version=$(python3 -c "
import json, sys
with open('$MARKETPLACE') as f:
    data = json.load(f)
for p in data['plugins']:
    if p['name'] == '$skill_name':
        print(p.get('version', ''))
        sys.exit()
print('')
")
    if [ -n "$fm_version" ] && [ -n "$mp_version" ] && [ "$fm_version" != "$mp_version" ]; then
      echo "FAIL  $skill_name: version mismatch — SKILL.md=$fm_version marketplace=$mp_version"
      errors=$((errors + 1))
    fi
  fi

  if [ $errors -eq "$errors_before" ]; then
    echo "  ok  $skill_name ($line_count lines, v${fm_version:-?})"
  fi
}

# Run checks
if [ -n "$1" ]; then
  if [ -d "$SCRIPT_DIR/$1" ]; then
    check_skill "$SCRIPT_DIR/$1"
  else
    echo "Skill not found: $1"
    exit 1
  fi
else
  for skill_dir in "$SCRIPT_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    [ -f "${skill_dir}SKILL.md" ] || continue
    check_skill "$skill_dir"
  done
fi

# Check README.md links point to existing directories
readme="$SCRIPT_DIR/README.md"
if [ -f "$readme" ]; then
  link_errors=0
  while IFS= read -r line; do
    # Extract markdown link paths like (general/some-skill/)
    echo "$line" | grep -oE '\(\./[a-z][a-z0-9-]+/?\)' | tr -d '()' | while read -r path; do
      target="$SCRIPT_DIR/$path"
      if [ ! -d "$target" ] && [ ! -d "${target%/}" ]; then
        echo "LINK  README.md: broken link → $path"
        echo "1" >> /tmp/skills-link-errors.$$
      fi
    done
  done < "$readme"
  if [ -f /tmp/skills-link-errors.$$ ]; then
    link_errors=$(wc -l < /tmp/skills-link-errors.$$)
    rm -f /tmp/skills-link-errors.$$
    errors=$((errors + link_errors))
  fi
fi

echo ""
if [ $errors -gt 0 ]; then
  echo "FAILED: $errors error(s)"
  exit 1
else
  echo "All checks passed."
fi
