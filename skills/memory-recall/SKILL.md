---
name: memory-recall
version: 1.0
description: "Restore project memory context by summarizing recent memory changes within a time window. Auto-activates when recalling memory, restoring context, or checking what was learned. Trigger keywords: recall memory, what do I know, memory summary, context restoration."
allowed-tools: Read, Grep, Glob, Bash
---

# Memory Recall

> **Purpose**: Context-restoration summary of project memory. Complements session-recap (git history) with what was learned, decided, and observed.

## Arguments

- No argument: last 24 hours
- `2d`/`48h`, `3d`/`72h`, `1w`, `YYYYMMDD`: alternate time windows

## Steps

1. Parse time window from argument
2. Read MEMORY.md index for full inventory and total count
3. Find memories added/modified in the window via `git log --since="<time>" --diff-filter=AM --name-only --pretty=format: -- .claude/memory/` (or equivalent memory directory)
4. Read each affected memory file

## Output

- **Memory Summary**: total count, breakdown by type (user/feedback/project/reference)
- **Recent Changes**: memories added or updated, grouped by type, one line each
- **Active Context**: project memories still load-bearing
- **Stale Candidates**: memories that may need updating based on age or contradictions

Concise, scannable. Focus on "what do I know" restoration, not exhaustive listing.
