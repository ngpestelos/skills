---
name: commands-audit
description: "Audit custom commands for structural completeness across global and project scopes. Auto-activates when auditing commands, checking command quality, or inventorying slash commands. Trigger keywords: commands audit, audit commands, command quality, missing usage."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.1.1"
---

# Commands Audit

> **Purpose**: Inventory and audit custom commands for structural completeness. Two modes: triage (scan all) and deep audit (single command).

## Scan Locations

- `~/.claude/commands/*.md` (global)
- `.claude/commands/*.md` (project)

Deduplicate across scopes — show each command once.

## Checklist

All checks are deterministic — pattern match only, no subjective judgment.

| Check | Pattern | Triage | Deep |
|-------|---------|--------|------|
| Usage | `## Usage` or code block with `/command-name` | `NO-USAGE` / `OK` | YES / NO |
| Instructions | `## Instructions`, `## Steps`, or `### Phase` | `NO-STEPS` / `OK` | YES / NO |
| Output format | `## Output` or output example in code block | — | YES / NO |
| Size | `wc -l` | show | show |
| Stale references | Paths matching `*.md`, `.claude/skills/*` — verify via Glob | — | CLEAN / list |

## Triage (no argument)

Run checklist (triage columns) on every command. Present as table sorted: flagged first, then by line count descending. End with: "X flagged / Y total (Z global, W project)."

## Deep Audit (with argument)

Search both scopes for `<name>.md`. Run full checklist. For each failed check, suggest a specific fix.
