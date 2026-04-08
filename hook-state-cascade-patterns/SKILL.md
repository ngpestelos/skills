---
name: hook-state-cascade-patterns
category: claude-code
description: "Reusable patterns for stateful Claude Code hooks: priority cascade routing, per-route daily cooldown, CWD-first state fallback, portable date parsing (GNU/BSD), live file verification. Trigger keywords: hook cascade, cooldown, route priority, state fallback, date epoch portable, hook state, daily limit."
metadata:
  version: "2.1.0"
---

# Stateful Hook Cascade Patterns

**Principles**: First match wins (exit after first suggestion). Daily limit per route via JSON cooldown (not hourly). Verify stale state against filesystem before suggesting.

## Priority Cascade with Daily Cooldown

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

## State File Fallback Chain

CWD-local first, then hardcoded fallback (hooks run from any CWD):

```bash
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
STATE_FILE=""
if [ -n "$CWD" ] && [ -f "$CWD/.claude/state/data.json" ]; then
  STATE_FILE="$CWD/.claude/state/data.json"
elif [ -f "$HOME/src/primary-repo/.claude/state/data.json" ]; then
  STATE_FILE="$HOME/src/primary-repo/.claude/state/data.json"
fi
[ -z "$STATE_FILE" ] && exit 0
```

## Consolidated jq Extraction

One jq call for all fields (~9ms on 547-line file) instead of one per field:

```bash
read -r FIELD_A FIELD_B FIELD_C <<< \
  $(jq -r '[
    (.section.field_a // ""),
    (.section.field_b // 0),
    (.section.array | length)
  ] | @tsv' "$STATE_FILE")
```

## Live Verification

State files go stale. Before suggesting, confirm the condition still holds against the filesystem (e.g., check `wc -l` before citing a line count from state).

## Portable Date Arithmetic (GNU/BSD)

GNU first (nix-managed), BSD fallback (stock macOS):

```bash
date_to_epoch() {
  date -d "$1" "+%s" 2>/dev/null \
    || date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null \
    || echo "0"
}
DAYS_SINCE=$(( ($(date "+%s") - $(date_to_epoch "$DATE_STR")) / 86400 ))
```
