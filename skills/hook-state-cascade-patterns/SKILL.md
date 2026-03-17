---
name: hook-state-cascade-patterns
version: 2.0
description: "Reusable patterns for stateful Claude Code hooks: priority cascade routing, per-route daily cooldown, CWD-first state fallback, portable date parsing (GNU/BSD), live file verification. Trigger keywords: hook cascade, cooldown, route priority, state fallback, date epoch portable, hook state, daily limit."
allowed-tools: Read, Grep, Glob, Bash
---

# Stateful Hook Cascade Patterns

## Core Principles

1. **First match wins** -- cascade through routes by priority; exit after first suggestion
2. **Daily limit per route** -- each route fires at most once per calendar day via JSON cooldown file (not hourly timers -- those let one route dominate all day)
3. **Silent fallback** -- when no route triggers, output nothing
4. **Live verification** -- verify stale state against filesystem before suggesting

## Pattern 1: Priority Cascade with Daily Cooldown

```bash
mkdir -p "$HOME/.claude/state"
COOLDOWN_FILE="$HOME/.claude/state/my-hook-cooldown.json"
[ ! -f "$COOLDOWN_FILE" ] && echo '{}' > "$COOLDOWN_FILE"
TODAY=$(date +%Y-%m-%d)

route_fired_today() {
  [ "$(jq -r --arg r "$1" '.[$r] // ""' "$COOLDOWN_FILE")" = "$TODAY" ]
}

record_route() {
  local tmp; tmp=$(mktemp)
  jq --arg r "$1" --arg d "$TODAY" '.[$r] = $d' "$COOLDOWN_FILE" > "$tmp" \
    && mv "$tmp" "$COOLDOWN_FILE"
}

# First match wins -- each route independent
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

exit 0  # silent fallback
```

## Pattern 2: State File Fallback Chain

Hooks run from any CWD. Resolve project state with CWD-local first, then hardcoded fallback.

```bash
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
STATE_FILE=""
if [ -n "$CWD" ] && [ -f "$CWD/.claude/state/data.json" ]; then
  STATE_FILE="$CWD/.claude/state/data.json"
elif [ -f "$HOME/src/primary-repo/.claude/state/data.json" ]; then
  STATE_FILE="$HOME/src/primary-repo/.claude/state/data.json"
fi
[ -z "$STATE_FILE" ] && exit 0  # no state = silent exit
```

## Pattern 3: Consolidated jq Extraction

Extract all fields in one call (~9ms on 547-line file) instead of spawning jq per field:

```bash
read -r FIELD_A FIELD_B FIELD_C <<< \
  $(jq -r '[
    (.section.field_a // ""),
    (.section.field_b // 0),
    (.section.array | length)
  ] | @tsv' "$STATE_FILE")
```

## Pattern 4: Live Verification Before Suggesting

State files go stale. Before firing a suggestion, confirm the condition still holds against the filesystem. Example: state says a file is 925 lines, but `wc -l` shows 400 after optimization -- skip the suggestion.

## Pattern 5: Portable Date Arithmetic (GNU/BSD)

nix-managed environments replace macOS BSD coreutils with GNU. Try GNU first, BSD fallback:

```bash
date_to_epoch() {
  date -d "$1" "+%s" 2>/dev/null \
    || date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null \
    || echo "0"
}
DAYS_SINCE=$(( ($(date "+%s") - $(date_to_epoch "$DATE_STR")) / 86400 ))
```

## Pattern Selection

| Need | Pattern |
|------|---------|
| Multiple suggestions, max 1/day each | 1: Priority cascade + daily cooldown |
| Hook reads project-specific state | 2: State file fallback chain |
| Multiple fields from one JSON | 3: Consolidated jq extraction |
| State might be stale | 4: Live filesystem verification |
| Date math on macOS + nix | 5: Portable date-to-epoch |
