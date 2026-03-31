---
name: ai-coding-tool-portability
description: "Guides portable configuration across Claude Code and OpenCode. Auto-activates when adding commands, mirroring configuration, or deciding where to put tool-specific features. Covers feature mapping, command mirroring via symlinks and home-manager, architecture layout. Trigger keywords: opencode, portability, commands mirroring, AGENTS.md, tool switching."
metadata:
  version: 1.0.0
---

# AI Coding Tool Portability

## Feature Mapping

| Concept | Claude Code | OpenCode | Sharing |
|---------|-------------|----------|---------|
| Project instructions | `CLAUDE.md` | Falls back to `CLAUDE.md` | Shared — never create `AGENTS.md` |
| Global instructions | `~/.claude/CLAUDE.md` | Falls back to `~/.claude/CLAUDE.md` | Shared |
| Project commands | `.claude/commands/*.md` | `.opencode/commands/*.md` | Symlinked |
| Global commands | `~/.claude/commands/*.md` | `~/.config/opencode/commands/*.md` | home-manager |
| Settings | `.claude/settings.json` | `opencode.json` | Separate schemas |
| Skills | `.claude/skills/*/SKILL.md` | Discovers `.claude/skills/` | Shared — never duplicate to `.opencode/skills/` |
| Hooks / Memory | `settings.json`, `projects/*/memory/` | No equivalent | Claude only |
| Agents | Task tool (built-in) | `.opencode/agents/*.md` | Different concepts |

## Adding Commands

**Portable command** (both tools):
1. Create canonical file in `config/claude/commands/<name>.md`
2. Add home-manager entries for both `~/.claude/commands/` and `~/.config/opencode/commands/`
3. Create project symlink: `.opencode/commands/<name>.md` -> `../../config/claude/commands/<name>.md`

**Claude-only command**: Create in `config/claude/commands/<name>.md`, add home-manager entry for Claude only.

## Forbidden

- **Creating `AGENTS.md`** — two instruction files invite drift
- **Duplicating skills to `.opencode/`** — OpenCode discovers `.claude/skills/` natively
- **Hardcoding tool-specific paths in shared commands** — keep commands tool-agnostic

## Architecture

```
config/claude/commands/          <- canonical source
  portable-cmd.md                <- mirrored to both tools
  claude-only-cmd.md             <- Claude home-manager only

.opencode/commands/              <- symlinks to canonical source
  portable-cmd.md -> ../../config/claude/commands/portable-cmd.md

flake.nix home.file entries:
  ~/.claude/commands/*            <- all commands
  ~/.config/opencode/commands/*   <- portable subset only
```

## Decision Tree

1. **Project/global instruction?** -> Edit `CLAUDE.md` (both tools read it)
2. **Command?** -> Tool-agnostic: add to both. Uses Claude features (skills/hooks/memory): Claude only.
3. **Setting?** -> Edit respective tool's config
4. **Skill?** -> `.claude/skills/` (shared; `name` must match directory)
5. **Hook/memory?** -> Claude only
