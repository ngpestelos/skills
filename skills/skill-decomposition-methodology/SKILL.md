---
name: skill-decomposition-methodology
description: "Systematic methodology for refactoring bloated skills (>500 lines) into focused sub-skills. Auto-activates when /skills-audit flags BLOAT or LARGE, or when planning skill optimization. Covers extraction criteria, pointer replacement, duplicate removal, structural heading compliance. Trigger keywords: skill refactor, skill split, bloat, decompose, extract sub-skill."
allowed-tools: Read, Grep, Glob
---

# Skill Decomposition Methodology

> **Purpose**: Systematic process for decomposing oversized skills into focused sub-skills without losing content or breaking cross-references.

## Trigger

Activates when:
- `/skills-audit` flags a skill as BLOAT (>800 lines) or LARGE (>500 lines)
- Planning to optimize a skill that mixes 3+ distinct domains
- Reviewing a skill with duplicated content sections (Quick Reference mirrors main content)
- A skill fails structural checks (missing `## Trigger`, `## Methodology`/`## Steps`, `## Output`)

## Core Principles

1. **Extract by cohesion**: Each sub-skill should cover ONE theme (e.g., "non-deterministic data" not "testing pitfalls")
2. **Replace with pointers, don't just delete**: Extracted blocks become 3-5 line summaries with skill links
3. **Duplicates are free cuts**: Content that appears twice in the same file can be removed entirely
4. **Structural headings are mandatory**: Every skill needs `## Trigger` + methodology section + `## Output`

## Methodology

### Step 1: Domain Analysis (~5 min)

Read the skill and identify distinct domains. A skill mixing 3+ domains is a decomposition candidate.

```
Example: A 1200-line testing patterns skill mixed 6 domains:
1. Test type selection + decision tree (core - keep)
2. Integration/Model/JS test patterns (core - keep)
3. Non-deterministic test data (UUID, time, timezone, HTML) → extract
4. Incomplete data setup (foreign keys, AJAX endpoints, conditionals) → extract
5. Cross-reference blocks (DB views, FriendlyId, AR cache) → trim to pointers
6. Duplicated Quick Reference sections → remove entirely
```

### Step 2: Extraction Planning

For each candidate sub-skill, verify:

| Check | Threshold | Action |
|-------|-----------|--------|
| Cohesive theme? | Single clear sentence describes it | Extract |
| Standalone useful? | Would activate independently | Extract |
| Size when extracted? | 100-300 lines | Extract |
| Already covered elsewhere? | Existing skill handles it | Pointer only |

### Step 3: Create Sub-Skills

Each extracted skill needs:

```markdown
---
name: [kebab-case-name]
description: "[Theme sentence]. Auto-activates when [triggers]."
allowed-tools: Read, Grep, Glob
---

# [Human-Readable Name]

## Trigger
[When this activates - 4-8 bullet points]

## Purpose
[One sentence]

## [Pattern sections - moved verbatim from parent]

## Output
[What the skill provides when activated - 3-4 bullet points]

## Related Skills
[Links back to parent + sibling skills]
```

### Step 4: Trim the Parent Skill

Three types of cuts (ordered by impact):

**1. Remove duplicates** (biggest wins, zero information loss):
```
- Quick Reference section that repeats tables from main content
- Performance comparison that duplicates earlier Performance Facts table
- Common Patterns table that mirrors Decision Matrix
```

**2. Replace extracted blocks with pointers** (~5 lines each):
```markdown
### Data Completeness Patterns

Tests fail with nil errors or wrong endpoints due to incomplete data setup.
For complete patterns (data graph setup, endpoint selection, conditional
UI prerequisites), see [sub-skill-name](/.claude/skills/sub-skill-name/SKILL.md).
```

**3. Condense verbose cross-references** (9-57 lines to 2-3 lines):
```markdown
### Webhook Testing

Webhooks are HTTP endpoints tested as integration tests. For comprehensive
patterns, see [webhook-patterns skill](/.claude/skills/webhook-patterns/SKILL.md).
```

### Step 5: Add Structural Headings

If missing, add to parent skill:
- `## Trigger` after frontmatter (6-8 bullet points of activation scenarios)
- `## Methodology` or `## Steps` wrapping the main decision logic
- `## Output` before footer (3-4 bullet points of what skill provides)

### Step 6: Update Skill Registry

In the skills registry (README or index):
1. Update parent skill's line count
2. Add new sub-skill entries in the same section
3. Include: Location, Auto-activates when, Prevents, Key guidance, Integration

## Verification Checklist

```bash
# 1. Line counts within budget
wc -l PARENT/SKILL.md          # <= 500
wc -l SUB-SKILL-1/SKILL.md     # 100-300
wc -l SUB-SKILL-2/SKILL.md     # 100-300

# 2. Structural headings present in parent
grep -n '^## Trigger\|^## Methodology\|^## Steps\|^## Output' \
  PARENT/SKILL.md

# 3. Cross-references to new skills exist in parent
grep -c 'sub-skill-name' PARENT/SKILL.md

# 4. No broken references (parent path unchanged)
grep -r 'parent-skill-name' skills/ | wc -l

# 5. Total lines <= original (no content invented)
wc -l PARENT/SKILL.md \
      SUB-SKILL-1/SKILL.md \
      SUB-SKILL-2/SKILL.md
```

## Output

When this skill activates, it provides:
1. Domain analysis of the bloated skill (which themes to extract)
2. Extraction plan with line ranges and target sub-skill names
3. Pointer text to replace extracted blocks
4. Verification commands to confirm the refactoring

## Integration

- **Related Skill**: [Skill Optimizer](/.claude/skills/skill-optimizer/SKILL.md) — trimming individual skills (duplicate elimination, example consolidation, content density)
- **Related Skill**: [Skill Stack Deduplication](/.claude/skills/skill-stack-deduplication/SKILL.md) — cross-layer deduplication (agent/skill/command)

## Key Takeaway

**Extract by cohesion, replace with pointers, remove duplicates** — a 1200-line skill becomes a 500-line parent + 2-3 focused sub-skills totaling fewer lines than the original.
