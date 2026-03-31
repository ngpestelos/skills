---
name: ai-coding-tool-portability
description: "Guides portable configuration across Claude Code and OpenCode. Auto-activates when adding commands, mirroring configuration, or deciding where to put tool-specific features. Covers feature mapping, command mirroring via symlinks and home-manager, architecture layout. Trigger keywords: opencode, portability, commands mirroring, AGENTS.md, tool switching."
metadata:
  version: 1.0.0
---

# AI Coding Tool Portability

## Trigger Keywords
opencode, portability, commands mirroring, AGENTS.md, tool switching

## Context
This skill guides configuration portability when a repo supports both Claude Code and OpenCode. Configuration is shared where possible, with tool-specific features staying in their native locations.

## Feature Mapping

| Concept | Claude Code | OpenCode | Shared? |
|---------|-------------|----------|---------|
| Project instructions | `CLAUDE.md` | `AGENTS.md` (falls back to `CLAUDE.md`) | Yes |
| Global instructions | `~/.claude/CLAUDE.md` | `~/.config/opencode/AGENTS.md` (falls back to `~/.claude/CLAUDE.md`) | Yes |
| Project commands | `.claude/commands/*.md` | `.opencode/commands/*.md` | Mirrored via symlinks |
| Global commands | `~/.claude/commands/*.md` | `~/.config/opencode/commands/*.md` | Mirrored via home-manager |
| Settings | `.claude/settings.json` | `opencode.json` | No - different schemas |
| Skills | `.claude/skills/*/SKILL.md` | Discovers `.claude/skills/` natively | Shared (requires `name` matching directory) |
| Hooks | `settings.json` UserPromptSubmit | No equivalent | Claude Code only |
| Memory | `~/.claude/projects/*/memory/` | No equivalent | Claude Code only |
| Agents | Task tool subagents (built-in) | `.opencode/agents/*.md` | No - different concepts |

## Required Patterns

### Adding a portable command (works in both tools)
1. Create the canonical file in `config/claude/commands/<name>.md`
2. Add home-manager entry for Claude: `file.".claude/commands/<name>.md"`
3. Add home-manager entry for OpenCode: `file.".config/opencode/commands/<name>.md"`
4. Create project symlink: `.opencode/commands/<name>.md` -> `../../config/claude/commands/<name>.md`

### Adding a Claude-only command
1. Create in `config/claude/commands/<name>.md`
2. Add home-manager entry for Claude only
3. No OpenCode mirroring needed

### Adding an OpenCode-only agent
1. Create in `.opencode/agents/<name>.md`
2. No Claude mirroring needed (different concept)

## Forbidden Patterns

- **Don't create `AGENTS.md`** - `CLAUDE.md` works as-is via OpenCode's fallback. Maintaining two instruction files invites drift.
- **Don't duplicate skills into `.opencode/skills/`** - OpenCode discovers `.claude/skills/` natively. Ensure frontmatter `name` matches directory name (`^[a-z0-9]+(-[a-z0-9]+)*$`).
- **Don't port hooks** - no OpenCode equivalent.
- **Don't port memory** - no OpenCode equivalent.
- **Don't hardcode tool-specific paths in shared commands** - commands should be tool-agnostic markdown.

## Architecture

```
config/claude/commands/          <- canonical source (all commands)
  commit.md                      <- portable
  recap.md                       <- portable
  reflect.md                     <- portable
  research.md                    <- portable
  capture-skill.md               <- Claude-only
  skills-audit.md                <- Claude-only
  ...

.claude/commands/                <- project commands (Claude Code)
  init-nix-shell.md              <- project-specific

.opencode/commands/              <- project commands (OpenCode, symlinked)
  commit.md -> ../../config/claude/commands/commit.md
  recap.md  -> ../../config/claude/commands/recap.md
  reflect.md -> ../../config/claude/commands/reflect.md
  research.md -> ../../config/claude/commands/research.md

flake.nix home.file entries:
  ~/.claude/commands/*            <- global Claude commands (all)
  ~/.config/opencode/commands/*   <- global OpenCode commands (portable subset)
  ~/.config/opencode/opencode.json <- global OpenCode config
```

## Decision Tree: Where to Put New Configuration

1. **Is it a project instruction?** -> Edit `CLAUDE.md` (both tools read it)
2. **Is it a global instruction?** -> Edit global `CLAUDE.md` (OpenCode falls back to `~/.claude/CLAUDE.md`)
3. **Is it a command?**
   - Tool-agnostic workflow? -> Add to both (follow "Adding a portable command" above)
   - Uses Claude-specific features (skills, memory, hooks)? -> Claude only
4. **Is it a setting?** -> Edit the respective tool's config (`settings.json` or `opencode.json`)
5. **Is it a skill?** -> Create in `.claude/skills/` (shared — OpenCode discovers it natively; ensure `name` matches directory name)
6. **Is it a hook/memory?** -> Claude Code only, no porting needed
