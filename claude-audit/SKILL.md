---
name: claude-audit
description: "Audit CLAUDE.md files for redundancy, verbosity, stale references, conflicting rules, and optimization opportunities. Auto-activates when discussing CLAUDE.md maintenance, reducing instruction token usage, or cleaning up project configuration."
license: MIT
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# Claude Audit

Audit all CLAUDE.md files for redundancy, verbosity, and optimization opportunities.

## Instructions

1. **Locate all CLAUDE.md files**: global (`~/.claude/CLAUDE.md`), project (`./CLAUDE.md`), and any nested ones.

2. **For each file, check**:
   - **Redundant instructions**: Rules repeating across files or duplicating Claude defaults
   - **Verbose phrasing**: Sections achievable in fewer tokens
   - **Memory candidates**: Stable facts belonging in auto-memory
   - **Stale references**: Links to files, commands, or skills that no longer exist
   - **Conflicting rules**: Instructions contradicting each other across files
   - **Cache-heavy sections**: Instructional blocks >30 lines extractable to a skill (reduces always-loaded prefix size)

3. **Present findings** organized by file, with line references.

4. **Classify each finding**:
   - `REMOVE` — redundant or duplicates defaults
   - `SHORTEN` — same meaning in fewer words
   - `MOVE` — belongs in memory or different file
   - `UPDATE` — stale reference
   - `RESOLVE` — conflicts with another instruction
   - `EXTRACT-TO-SKILL` — large block better as conditionally-loaded skill

5. **Ask the user** which changes to implement. Do not modify files without approval.
