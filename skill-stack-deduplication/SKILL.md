---
name: skill-stack-deduplication
description: "Eliminates content duplication across Claude Code agent/skill/command file layers by establishing clear separation of concerns. Auto-activates when reviewing skill architecture, auditing agent definitions, refactoring command files, or when duplicate content detected across .claude/ files. Covers reference hierarchy design, responsibility assignment, content deduplication, cross-reference verification. Trigger keywords: deduplication, separation of concerns, skill stack, agent refactor, command refactor, duplicate content, layer responsibility, reference hierarchy, context window optimization."
metadata:
  version: "1.0.2"
---

# Skill Stack Deduplication

Every concept has exactly one canonical location. Files reference that location instead of copying content.

## Reference Hierarchy

```
CLAUDE.md (permanent directives, verification standards)
    |
foundation-skill/SKILL.md (canonical methodology)
    |
extension-skill/SKILL.md (unique execution steps, output templates)
    |
agents/agent-name.md (persona, behavior, skill delegation)
    |
commands/command-name.md (invocation guide: usage, when to use)
```

Each layer only contains content unique to its responsibility. Reference up, don't copy.

## Layer Responsibilities

| Layer | Contains | Does NOT Contain |
|---|---|---|
| CLAUDE.md | Permanent directives, verification standards | Skill-specific methodology |
| Foundation Skill | Canonical methodology | Agent behavior, invocation details |
| Extension Skill | Unique execution steps, output templates | Foundation methodology, agent persona |
| Agent | Persona, behavior rules, context sensitivity | Methodology details, output templates |
| Command | Usage, "what it does", "when to use" | Full methodology, benefits lists |

## Forbidden Patterns

**Copy-pasting methodology across files** — if the same process steps appear in both an agent and a skill, the agent must reference the skill instead.

**Redefining CLAUDE.md directives** — permanent rules (Reality Filter labels, verification standards) belong only in CLAUDE.md. Other files use a one-line reference:

```markdown
# WRONG: Re-listing verification labels in agent file
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
- **Permanent rules/verification standards** -> CLAUDE.md
- **Already defined elsewhere** -> Reference it, don't copy it

## Deduplication Audit Process

1. **Count lines** across all files in the stack: `wc -l agent.md skill/SKILL.md command.md`
2. **Identify overlap** by grepping for repeated phrases across files
3. **Assign responsibility** per the layer table above
4. **Rewrite each file** keeping only its unique content + references
5. **Verify cross-references** resolve to existing files
6. **Confirm no methodology lost** — only deduplicated
