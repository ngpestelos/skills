---
name: skills-audit
description: "Inventory and audit skills for spec compliance and optimization. Two modes: triage (scan all) and deep audit (single skill). Auto-activates when auditing skills, checking skill quality, or optimizing skill files. Trigger keywords: skills audit, audit skill, skill quality, spec check, optimize skill."
allowed-tools: Read Grep Glob Bash
metadata:
  version: "1.0.0"
---

# Skills Audit

> **Purpose**: Inventory and audit skills. Two modes: triage (scan all) and deep audit (single skill).

## Mode 1: Triage (no argument)

1. **Scan** `~/.claude/skills/*/SKILL.md` (user) and `.claude/skills/*/SKILL.md` (project). Extract: name, scope, line count.
2. **Present table**: Skill | Scope | Lines | Status
   - `LARGE` (>300 lines), `DUP` (both scopes), `OK`
   - Flagged first, then by line count descending
   - Summary: "X flagged / Y total (Z user, W project)"

**Critical**: Triage MUST NOT read SKILL.md contents (prevents context bloat).

## Mode 2: Deep Audit (with argument)

Search both scopes for the skill name.

### Phase 1: Spec Check

Read SKILL.md and any `references/`. Checklist:

| Check | Criteria |
|-------|----------|
| `name` | Lowercase-hyphen, 1-64 chars, matches directory |
| `description` | ≤1024 chars |
| Frontmatter keys | Only: name, description, license, compatibility, metadata, allowed-tools |
| Body lines | <500 |
| Body tokens | <5000 (words x 1.3) |

### Phase 2: Five-Step Optimize

- **Question**: Is each section necessary? Does it restate obvious knowledge?
- **Delete**: Obvious framework knowledge, CLAUDE.md duplicates, hypothetical scenarios (grep to verify), FORBIDDEN sections that just invert REQUIRED patterns
- **Tighten**: 1 line > 1 paragraph when possible

### Phase 3: Decompose (if >300 lines after Phase 2)

Extract to `references/` with pointers. Fix frontmatter issues.

### Phase 4: Report

What was deleted and why, final line count, files created/removed.
