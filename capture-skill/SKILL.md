---
name: capture-skill
version: 1.2
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
3. 3+ matches with one skill → show it, ask "**Merge**, **proceed**, or **abort**?"
4. 0-2 matches → proceed silently

**Decision**: match found → update existing. No match → create new.

## Phase 2: Generate Content

**Updating**: Read existing skill. Add new content with dates. Preserve existing — only add, don't remove.

**Creating**: Use this skill's own frontmatter as the template. Required fields:

| Field | Rule |
|-------|------|
| `name` | Match directory name, `^[a-z0-9]+(-[a-z0-9]+)*$`, 1-64 chars |
| `description` | 20-1024 chars, include trigger keywords |
| `version` | Semver, start at 1.0 |
| `allowed-tools` | Restrict to what the skill needs |
| Non-standard keys | Must go under `metadata:` |

Required sections: `# Heading` (human-readable), Purpose line, then content sections appropriate to the pattern.

## Phase 3: Validate + Present

**Validation** (before showing to user):
- Frontmatter fields match rules above
- < 300 lines, < 5000 tokens (user can override with "save anyway")
- If skills repo has `check.sh`, run it against the skill

**Present**: Show proposed skill (or diff for updates). Ask if the pattern is captured correctly. After approval, write files.

## Phase 4: Optimize first version (new skills only)

**Skip for updates.** For newly-created skills only, run the `five-step-optimizer` skill against the file you just wrote, then show the user the optimized diff and the resulting line/token count.

First drafts reliably over-include sections Claude already knows (verification steps, generic ops hygiene) or that don't change execution (discovery context, "when to use" duplicates of frontmatter). Running the optimizer once at creation forces a pass of Step 1 (question every requirement) and Step 2 (delete) before the skill calcifies. Updates skip this because their content has already been lived-with.

Bump `version` to 1.1 after optimization to reflect the post-optimize state.
