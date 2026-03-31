---
name: commands-audit
version: 1.0
description: "Audit custom commands for structural completeness across global and project scopes. Auto-activates when auditing commands, checking command quality, or inventorying slash commands. Trigger keywords: commands audit, audit commands, command quality, missing usage."
allowed-tools: Read, Grep, Glob, Bash
---

# Commands Audit

> **Purpose**: Inventory and audit custom commands for structural completeness. Two modes: triage (scan all) and deep audit (single command).

## Mode 1: Triage

Scan command directories for `*.md`:
- `~/.claude/commands/*.md` (global)
- `.claude/commands/*.md` (project)
- If `config/claude/commands/` exists (source repo): deduplicate against global, prefer source path

For each command, extract:

| Field | How |
|-------|-----|
| Name | Filename without `.md` |
| Scope | `global` or `project` |
| Lines | `wc -l` |
| Usage | `## Usage` heading or code block with `/command-name` |
| Steps | `## Instructions`, `## Steps`, or `### Phase` heading |

Present as table with status flags:
- `NO-USAGE` — missing usage/invocation example
- `NO-STEPS` — missing instructions or phase structure
- `OK` — both present

Show flagged first, then by line count descending. End with: "X flagged / Y total (Z global, W project)."

## Mode 2: Deep Audit

Argument: command name (e.g., `commit`). Search both scopes for `<name>.md`.

Run deterministic checklist:

| Check | Criteria | Result |
|-------|----------|--------|
| Usage | `## Usage` or code block with `/command-name` | YES / NO |
| Instructions | `## Instructions`, `## Steps`, or `### Phase` | YES / NO |
| Output format | `## Output` or output example in code block | YES / NO |
| Size | Line count (informational) | N lines |
| Stale references | Paths matching `*.md`, `.claude/skills/*` — verify via Glob | CLEAN / list |

For each failed check, suggest a specific fix (e.g., "Add `## Usage` section with invocation example").

## Design Constraints

- All checks are deterministic — no subjective quality judgment
- No arbitrary line-count thresholds
- Deep audit reads exactly one command file per scope match
