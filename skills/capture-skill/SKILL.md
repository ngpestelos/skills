---
name: capture-skill
version: 1.0
description: "Extract patterns from the current session into a reusable skill file. Auto-activates when discussing skill creation, pattern extraction, or anti-pattern documentation. Trigger keywords: capture skill, extract pattern, create skill, new skill, anti-pattern."
allowed-tools: Read, Grep, Glob, Bash
---

# Capture Skill

> **Purpose**: Extract recurring patterns, anti-patterns, and solutions from a session into a skill file (update existing or create new).

## Phase 1: Analyze + Duplicate Check

Run in parallel:

**Analyze context** — Review recent conversation for:
- Anti-patterns discovered and solutions
- Common mistakes and fixes
- Trigger scenarios and keywords
- Discovery context (dates, error messages)

Extract: pattern name (kebab-case for directory, gerund form for heading), trigger keywords, core principles, code examples.

**Duplicate check** — Search existing skills:
1. Extract 3-5 core keywords from the proposed skill
2. Search: `grep -ril "keyword1\|keyword2\|keyword3" .claude/skills/*/SKILL.md ~/.claude/skills/*/SKILL.md`
3. If 3+ keyword matches with any single skill: flag it, show matching skill, ask "**Merge**, **proceed**, or **abort**?"
4. If 0-2 matches: proceed silently

**Decision**: match found → update existing skill. No match → create new skill.

## Phase 2: Generate Content

### Updating existing skill

1. Read existing skill
2. Add new anti-patterns, examples, discovery context (with date)
3. Preserve existing content — only add, don't remove

### Creating new skill

Required frontmatter:

```yaml
---
name: [kebab-case-directory-name]
version: 1.0
description: "What it does. Auto-activates when [scenarios]. Trigger keywords: [list]."
allowed-tools: Read, Grep, Glob, Bash
---
```

Required sections: `# Heading` (human-readable), Purpose line, and content sections appropriate to the pattern.

Frontmatter rules:
- `name` must match directory name exactly: `^[a-z0-9]+(-[a-z0-9]+)*$` (1-64 chars)
- `description`: 20-1024 chars, include trigger keywords
- `version`: semver, start at 1.0
- Non-standard keys go under `metadata:`

## Phase 3: Validate + Present

**Validation** (inline, before showing to user):
- Frontmatter: `name` matches directory, `description` present, `allowed-tools` specified
- Line budget: 300 lines max (user can override with "save anyway")
- Token budget: < 5000 tokens estimated
- Discovery context includes dates
- If skills repo has `check.sh`, run it against the new skill

**Present**: Show proposed skill (or diff for updates). Ask if the pattern is captured correctly. After approval, write files.

## Output

Creates or updates `skills/[skill-name]/SKILL.md`. Reports validation results.

## Constraints

- `name` must exactly match directory name in kebab-case (OpenCode validates this)
- Most skills use `Read, Grep, Glob, Bash` — restrict as appropriate
- Keep non-standard frontmatter keys under `metadata:` to pass spec checks
