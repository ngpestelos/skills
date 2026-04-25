---
name: recap
description: "Summarize recent git commits for context restoration at session start or after context-switching, grouping by directory or theme and highlighting resume points. Supports configurable time windows (24h, 2d, 1w, etc.). Auto-activates when recapping changes, reviewing recent work, or restoring session context. Trigger keywords: recap, recent changes, what happened, git summary, context restore, session start, pick up where I left off."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

# Session Recap

> **Purpose**: Context-restoration summary of recent commits. Use at session start or after context-switching.

## Arguments

- No argument: last 24 hours
- `2d`/`48h`, `3d`/`72h`, `1w`, `YYYYMMDD`: alternate time windows

## Steps

1. Parse time window from argument
2. Gather: `git log --since="<time>" --all --no-merges --stat` (one pass)
3. Group commits by top-level directory or natural theme — let repo structure guide grouping
4. Filter out bulk/noise commits (automated backups, state files) unless they're the only activity

## Output

- **Key Themes**: 2-3 sentence summary of focus areas
- **Changes by Area**: commits grouped by directory or theme, one line per commit
- **Resume Points**: where to pick up work, based on most recent non-maintenance commits

Concise, scannable. Focus on context restoration, not stakeholder reporting.
