---
name: skill-stack-deduplication
description: "Eliminates content duplication across Claude Code agent/skill/command file layers by establishing clear separation of concerns. Auto-activates when reviewing skill architecture, auditing agent definitions, refactoring command files, or when duplicate content detected across .claude/ files. Covers reference hierarchy design, responsibility assignment, content deduplication, cross-reference verification. Trigger keywords: deduplication, separation of concerns, skill stack, agent refactor, command refactor, duplicate content, layer responsibility, reference hierarchy, context window optimization."
metadata:
  version: 1.0.0
---

# Skill Stack Deduplication

> **Purpose**: Eliminate content duplication across Claude Code agent/skill/command layers by establishing clear single-responsibility files connected through references.

## Core Principles

1. **Each file has one job**: Agent = persona and behavior, Skill = methodology and execution steps, Command = invocation guide
2. **Reference up, don't copy**: Each layer references the layer above it instead of duplicating content
3. **CLAUDE.md is the permanent directive layer**: Reality Filter, verification standards, and core rules live there — never redefine them in skills or agents
4. **Canonical source per concept**: Every piece of methodology has exactly one authoritative location

## Reference Hierarchy

```
CLAUDE.md (permanent directives: Reality Filter, verification standards)
    |
foundation-skill/SKILL.md (canonical methodology, e.g., reality-filter)
    |
extension-skill/SKILL.md (extends foundation: unique execution steps, output templates)
    |
agents/agent-name.md (persona, behavior, context sensitivity, skill delegation)
    |
commands/command-name.md (invocation guide: usage, what it does, when to use)
```

Each layer only contains content unique to its responsibility. Shared concepts are referenced, not repeated.

## Required Patterns

### Layer Responsibilities

| Layer | Contains | Does NOT Contain |
|---|---|---|
| CLAUDE.md | Permanent directives, verification standards | Skill-specific methodology |
| Foundation Skill | Canonical methodology (e.g., PS technique) | Agent behavior, invocation details |
| Extension Skill | Unique execution steps, output templates | Foundation methodology, agent persona |
| Agent | Persona, behavior rules, context sensitivity | Methodology details, output templates |
| Command | Usage, "what it does", "when to use" | Full methodology, benefits lists, examples |

### Reference Syntax

```markdown
## In a skill referencing another skill:
See [five-step-optimizer](/.claude/skills/five-step-optimizer/SKILL.md) for optimization methodology.

## In an agent referencing its skill:
Follow [reality-filter skill](/.claude/skills/reality-filter/SKILL.md) for verification labeling and evidence hierarchy.

## In any file referencing CLAUDE.md:
Reality Filter verification standards are defined in CLAUDE.md.
```

## Forbidden Patterns

### Copy-pasting methodology across files

```markdown
# WRONG: Same layers defined in both agent AND skill
# agent/document-analyzer.md
**Layer 1 - Important Passages (10-20%)**:
- Identify most valuable passages...

# skill/document-analyzer/SKILL.md
**Layer 1 - Important Passages (10-20%)**:
- Identify most valuable passages...
```

```markdown
# RIGHT: Skill references foundation, agent references skill
# skill/document-analyzer/SKILL.md
Apply optimization patterns from [five-step-optimizer](/.claude/skills/five-step-optimizer/SKILL.md).

# agent/example-agent.md
Follow [reality-filter skill](/.claude/skills/reality-filter/SKILL.md) for methodology.
```

### Redefining CLAUDE.md directives

```markdown
# WRONG: Re-listing Reality Filter labels in agent file
**Verification Labeling System**:
- [Verified] - Direct content from the analyzed document
- [Inference] - Derived from observable patterns...

# RIGHT: One-line reference
Follow CLAUDE.md "AI Response Accuracy & Verification Standards" for verification labeling.
```

## Quick Decision Tree

- **Methodology/process steps** -> Skill file (canonical source)
- **Persona/behavior/context rules** -> Agent file
- **Invocation syntax/when-to-use** -> Command file
- **Verification standards/permanent rules** -> CLAUDE.md
- **Already defined elsewhere** -> Reference it, don't copy it

## Deduplication Audit Process

1. **Count lines** across all files in the stack: `wc -l agent.md skill/SKILL.md command.md`
2. **Identify overlap** by grepping for repeated phrases across files
3. **Assign responsibility** per the layer table above
4. **Rewrite each file** keeping only its unique content + references
5. **Verify cross-references** resolve to existing files
6. **Confirm no methodology lost** — only deduplicated

### Violation Detection

```bash
# Find potential duplication: same phrase in multiple .claude/ files
grep -r "Layer 1\|Layer 2\|Layer 3\|Verification Label\|Reality Filter" .claude/agents/ .claude/skills/ .claude/commands/ | \
  awk -F: '{print $2}' | sort | uniq -c | sort -rn | head -20
```

## Key Takeaway

Every concept has exactly one canonical location. Agent, skill, and command files reference that location instead of copying content. The result: ~60% fewer lines, zero duplication, and clear single-responsibility files.
