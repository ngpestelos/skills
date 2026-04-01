---
name: hermes-profile-skill-awareness
description: "Make a Hermes profile aware of a skill that lives in a project repository. Updates profile SOUL.md with skill documentation, invocation patterns, and key features."
version: 1.0.0
---

# Hermes Profile Skill Awareness

Update a Hermes profile's SOUL.md to document a skill that lives in the project repository. This bridges the gap between project-specific automation (skills) and the profile's contextual knowledge.

## When to Use

- You've created a skill in `.claude/skills/` (or similar)
- You want the Hermes profile to "know about" this skill
- Users should understand when and how to invoke the skill via the profile

## Prerequisites

- Hermes profile exists at `~/.hermes/profiles/<name>/` or `~/src/hermes-config/profiles/<name>/`
- Skill file exists in the project repo (e.g., `.claude/skills/<skill-name>/SKILL.md`)
- You have write access to the profile's SOUL.md

## Procedure

### 1. Read the Skill

Read the skill file to understand:
- What it does (high-level purpose)
- When to use it (triggers, use cases)
- How to invoke it (commands, natural language patterns)
- Key features or flags

```bash
read_file(path="<project>/.claude/skills/<skill-name>/SKILL.md")
```

### 2. Identify Insertion Point

Read the profile SOUL.md and find where skill/tool documentation belongs. Common locations:
- After "Key Documentation" section
- In a dedicated "Available Skills" or "Tools" section
- Near related workflow documentation

### 3. Add Skill Section

Insert a new section following this structure:

```markdown
## The <Skill-Name> Skill

Brief one-line description of what the skill does.

### What It Does
1-2 sentence summary of the skill's purpose and workflow.

### When to Use
- Bullet list of use cases
- When this skill is the right tool for the job

### Invocation
```bash
# Natural language trigger
"<example natural language invocation>"

# Or explicit skill reference
"Read <skill-path> and follow its instructions for: <task>"
```

### Key Features
- **Feature name** — Brief description
- **Another feature** — Brief description
```

### 4. Commit Changes

```bash
cd ~/src/hermes-config  # or wherever profile is version-controlled
git add profiles/<name>/SOUL.md
git commit -m "Update <name> profile SOUL.md with <skill-name> documentation

Add section on the <skill-name> skill:
- Purpose and workflow
- When to use it
- Invocation patterns
- Key features

<skill-name> is now the primary method for <task type>."