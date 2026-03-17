---
name: skill-decomposition-methodology
version: 2.0
description: "Methodology for refactoring bloated skills (>500 lines) into focused sub-skills. Activates when /skills-audit flags BLOAT or LARGE, or when a skill mixes 3+ distinct domains."
allowed-tools: Read, Grep, Glob
---

# Skill Decomposition Methodology

> **Purpose**: Decompose oversized skills into focused sub-skills without losing content or breaking cross-references.

## Trigger

- `/skills-audit` flags a skill as BLOAT (>800 lines) or LARGE (>500 lines)
- A skill mixes 3+ distinct domains
- A skill has duplicated content (Quick Reference mirrors main content)

## Methodology

### Step 1: Domain Analysis

Read the skill and tag each section with its domain. A skill mixing 3+ domains is a decomposition candidate. Classify each domain: **keep** (core to the skill's identity), **extract** (cohesive, standalone-useful, 100-300 lines when extracted), or **cut** (duplicated or already covered by another skill).

### Step 2: Extraction Planning

For each candidate, verify all four criteria before extracting:

| Check | Threshold |
|-------|-----------|
| Cohesive theme? | Single sentence describes it |
| Standalone useful? | Would activate independently |
| Extracted size? | 100-300 lines |
| Already covered elsewhere? | If yes, pointer only |

### Step 3: Create Sub-Skills

Each extracted skill must have: frontmatter (`name`, `description`, `allowed-tools`), `## Trigger`, `## Purpose`, pattern sections moved verbatim from parent, `## Output`, `## Related Skills` linking back to parent.

### Step 4: Trim the Parent

Three cut types, ordered by impact:

**1. Remove duplicates** (zero information loss) — Quick Reference sections that repeat tables from main content, performance comparisons that duplicate earlier tables, any section that mirrors another.

**2. Replace extracted blocks with pointers** — Each extracted block becomes a 3-5 line summary linking to the sub-skill:

```markdown
### [Extracted Topic]

[One-sentence summary of what was extracted and why it matters.]
See [sub-skill-name](/.claude/skills/sub-skill-name/SKILL.md).
```

**3. Condense verbose cross-references** — Reduce 9-57 line cross-reference blocks to 2-3 lines with a skill link.

### Step 5: Verify

Confirm: parent <= 500 lines, each sub-skill 100-300 lines, structural headings present (`## Trigger`, `## Methodology`/`## Steps`, `## Output`), cross-references to new sub-skills exist in parent, total lines <= original (no content invented).

## Output

1. Domain analysis of the bloated skill (which themes to extract, keep, cut)
2. Extraction plan with target sub-skill names
3. Pointer text to replace extracted blocks
4. Verification that line budgets and structural requirements are met

## Related Skills

- [Skill Optimizer](/.claude/skills/skill-optimizer/SKILL.md) — trimming individual skills
- [Skill Stack Deduplication](/.claude/skills/skill-stack-deduplication/SKILL.md) — cross-layer deduplication
