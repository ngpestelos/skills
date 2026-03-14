---
name: hook-state-cascade-patterns
description: "Reusable patterns for stateful Claude Code hooks: priority cascade routing, per-route daily cooldown, CWD-first state fallback, portable date parsing (GNU/BSD), live file verification before suggesting. Auto-activates when building hooks that read state files, need cooldown logic, or route to different actions. Trigger keywords: hook cascade, cooldown, route priority, state fallback, date epoch portable, hook state, daily limit. (project)"
allowed-tools: Read, Grep, Glob, Bash
---

# Stateful Hook Cascade Patterns

> **Purpose**: Reusable patterns for Claude Code hooks that read project state, route to prioritized actions, and avoid suggestion fatigue through daily cooldowns.

## Core Principles

1. **First match wins** -- cascade through routes by priority; exit after first suggestion
2. **Daily limit per route** -- each route fires at most once per calendar day via JSON cooldown file
3. **Silent fallback** -- when no route triggers, output nothing (no generic noise)
4. **Live verification** -- verify stale state data against filesystem before suggesting

## Pattern 1: Priority Cascade with Daily Cooldown

### Structure

```bash
# Cooldown infrastructure
mkdir -p "$HOME/.claude/state"
COOLDOWN_FILE="$HOME/.claude/state/my-hook-cooldown.json"
[ ! -f "$COOLDOWN_FILE" ] && echo '{}' > "$COOLDOWN_FILE"
TODAY=$(date +%Y-%m-%d)

route_fired_today() {
  local last_fired
  last_fired=$(jq -r --arg r "$1" '.[$r] // ""' "$COOLDOWN_FILE")
  [ "$last_fired" = "$TODAY" ]
}

record_route() {
  local tmp; tmp=$(mktemp)
  jq --arg r "$1" --arg d "$TODAY" '.[$r] = $d' "$COOLDOWN_FILE" > "$tmp" \
    && mv "$tmp" "$COOLDOWN_FILE"
}

# Route cascade -- first match wins
if ! route_fired_today "route-a" && [ condition ]; then
  record_route "route-a"
  echo "Suggestion for route A"
  exit 0
fi

if ! route_fired_today "route-b" && [ condition ]; then
  record_route "route-b"
  echo "Suggestion for route B"
  exit 0
fi

# Silent fallback
exit 0
```

### Cooldown anti-pattern

```bash
# WRONG -- hourly cooldown allows the same route to dominate all day
LAST=$(stat -c %Y "$COOLDOWN_FILE")
NOW=$(date +%s)
[ $((NOW - LAST)) -lt 3600 ] && exit 0

# RIGHT -- per-route daily limit
# Each route gets independent tracking. Route 1 firing doesn't block Route 2.
# After all routes fire once today, cascade silently exhausts.
```

## Pattern 2: State File Fallback Chain

Hooks run from any CWD. Project state may not be local.

```bash
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
STATE_FILE=""

# CWD-local first
if [ -n "$CWD" ] && [ -f "$CWD/.claude/state/data.json" ]; then
  STATE_FILE="$CWD/.claude/state/data.json"
# Hardcoded fallback for primary repo
elif [ -f "$HOME/src/PARA/.claude/state/data.json" ]; then
  STATE_FILE="$HOME/src/PARA/.claude/state/data.json"
fi

# No state = silent exit (not an error)
[ -z "$STATE_FILE" ] && exit 0
```

## Pattern 3: Consolidated jq Extraction

Extract all needed fields in a single jq call (~9ms on 547-line file):

```bash
read -r FIELD_A FIELD_B FIELD_C <<< \
  $(jq -r '[
    (.section.field_a // ""),
    (.section.field_b // 0),
    (.section.array | length)
  ] | @tsv' "$STATE_FILE")
```

Anti-pattern -- multiple jq invocations (3x slower, 3x process spawning):

```bash
FIELD_A=$(jq -r '.section.field_a' "$STATE_FILE")
FIELD_B=$(jq -r '.section.field_b' "$STATE_FILE")
FIELD_C=$(jq -r '.section.array | length' "$STATE_FILE")
```

## Pattern 4: Live Verification Before Suggesting

State files can be stale. Verify against filesystem before firing.

```bash
# State says skill is 925 lines, but user may have optimized it
ACTUAL_LINES=0
for DIR in "$CWD/.claude/skills" "$HOME/.claude/skills"; do
  if [ -f "$DIR/$SKILL_NAME/SKILL.md" ]; then
    ACTUAL_LINES=$(wc -l < "$DIR/$SKILL_NAME/SKILL.md" | tr -d ' ')
    break
  fi
done

# Only suggest if live check confirms the problem
[ "$ACTUAL_LINES" -gt 500 ] && echo "Skill is bloated"
```

## Pattern 5: Portable Date Arithmetic

nix-managed environments replace macOS BSD coreutils with GNU.

```bash
# GNU first (nix/Linux), BSD fallback (vanilla macOS)
date_to_epoch() {
  date -d "$1" "+%s" 2>/dev/null \
    || date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null \
    || echo "0"
}

DAYS_SINCE=$(( ($(date "+%s") - $(date_to_epoch "$DATE_STR")) / 86400 ))
```

Anti-pattern -- assuming BSD date on macOS:

```bash
# Fails with nix-managed GNU coreutils: "date: invalid option -- 'j'"
date -j -f "%Y-%m-%d" "$DATE_STR" "+%s"
```

## Quick Decision Tree

| Need | Pattern |
|------|---------|
| Multiple suggestions, max 1/day each | Priority cascade + daily cooldown |
| Hook reads project-specific state | State file fallback chain |
| Multiple fields from one JSON | Consolidated jq extraction |
| State might be stale | Live filesystem verification |
| Date math in shell on macOS+nix | Portable date-to-epoch helper |

## Reference Implementation

`~/src/dotfiles/config/claude/hooks/self-improvement.sh` uses all 5 patterns:
- 5-route cascade (bloat, capture-drought, audit-overdue, orphans, unused-ratio)
- Daily cooldown at `~/.claude/state/self-improvement-cooldown.json`
- CWD then PARA fallback for `command-usage.json`
- Live `wc -l` on skill files before Route 1
- GNU/BSD portable `date_to_epoch`

## Integration

- **Parent Skill**: [claude-code-hook-development](~/.claude/skills/claude-code-hook-development/SKILL.md) -- hook basics
- **Reference Script**: `~/src/dotfiles/config/claude/hooks/self-improvement.sh`
- **Related Commands**: `/skills-audit`, `/capture-skill`

## When to Use This Skill

This skill auto-activates when:
- Building a hook that needs to route to different suggestions
- Adding cooldown or rate-limiting to hook output
- Reading project state from hooks that run in any CWD
- Doing date arithmetic in shell scripts on macOS with nix

## Discovery Context

- **Date**: February 23, 2026
- **Scenario**: Reimplemented self-improvement.sh from generic hint to 5-route priority cascade with daily cooldown

## Key Takeaway

Stateful hooks need three things: a priority cascade (first match wins, then exit), per-route daily cooldowns (JSON file, not timers), and silent fallback (no output beats generic output).
