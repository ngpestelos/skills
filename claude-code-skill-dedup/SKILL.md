---
name: claude-code-skill-dedup
description: "Detect and remove duplicate /slash-command registrations in Claude Code caused by the same name existing in multiple source locations (.claude/commands/, .claude/skills/, ~/.claude/skills/). Auto-activates when slash commands appear multiple times in /help or the available skills list, or when investigating duplicate command entries. Trigger keywords: duplicate command, duplicate skill, appears twice, multiple registrations, slash command list, commands skills overlap."
version: 1.1.0
author: Nestor Pestelos
---

# Claude Code Skill Dedup

Detect and remove duplicate `/slash-command` registrations caused by name collisions across Claude Code's three source locations.

## Why Duplicates Occur

Claude Code registers slash commands from three locations simultaneously:
1. `.claude/commands/*.md` (project commands)
2. `.claude/skills/*/SKILL.md` (project skills)
3. `~/.claude/skills/*/SKILL.md` (global skills, symlinked from `~/src/skills/`)

The same name in any two sources creates a duplicate entry in the slash command list.

## Detection

Run from the project root:

```python
import os

project_commands = set(f.replace('.md','') for f in os.listdir('.claude/commands/'))
project_skills   = set(os.listdir('.claude/skills/'))
global_skills    = set(os.listdir(os.path.expanduser('~/.claude/skills/')))

print("Command + project skill:", sorted(project_commands & project_skills))
print("Command + global skill:", sorted(project_commands & global_skills))
print("Project skill + global skill:", sorted(project_skills & global_skills))
```

## Resolution

**Keep the skill, remove the command or global duplicate.**

| Duplicate type | Action |
|---|---|
| Command + skill (project or global) | `rm .claude/commands/<name>.md` |
| Project skill + global skill | Remove symlink + source (see below) |

### Removing a global skill symlink

```bash
target=$(readlink ~/.claude/skills/<name>)
rm ~/.claude/skills/<name>
rm -rf "$target"
```

Verify the target path with `readlink` first — some source dirs are nested (e.g. `~/src/skills/subdir/<name>/`).

Restart the Claude Code session after cleanup for the list to refresh.
