---
name: portable-ai-cli-patterns
description: "Guides dual-tool configuration for Claude Code and OpenCode. Auto-activates when working with cross-tool command deployment, AGENTS.md decisions, skill/command sharing, or promoting project-local skills/agents to global scope. Covers compatibility matrix, single-source commands via home-manager, forbidden duplication patterns, skill/agent promotion workflow. Trigger keywords: opencode, claude code, ai cli, dual tool, commands deployment, AGENTS.md, backward compatibility, portable commands, promote skill, global skill."
metadata:
  version: "1.0.1"
---

# Portable AI CLI Patterns

OpenCode provides backward compatibility with Claude Code's file conventions — most configuration is shared from a single source.

## Compatibility Matrix

| Asset | Claude Code | OpenCode | Shared? |
|-------|------------|----------|---------|
| `CLAUDE.md` (project) | Native | Fallback (when no AGENTS.md) | Yes |
| `~/.claude/CLAUDE.md` (global) | Native | Fallback | Yes |
| `.claude/skills/` | Native | Searched alongside .opencode/skills/ | Yes |
| `~/.claude/commands/` | Native | Not read | No |
| `~/.config/opencode/commands/` | Not read | Native | No |
| `.claude/commands/` (project) | Native | Not read | No |
| `.opencode/commands/` (project) | Not read | Native | No |
| `settings.json` / hooks | Claude Code only | No equivalent | No |

## Required Patterns

### Single-source commands via home-manager
All global commands are authored once in `config/claude/commands/` and deployed to both tools via `home.file` entries in `flake.nix`:

```nix
# Claude Code commands
file.".claude/commands/commit.md" = { source = ./config/claude/commands/commit.md; force = true; };
# OpenCode commands (same source)
file.".config/opencode/commands/commit.md" = { source = ./config/claude/commands/commit.md; force = true; };
```

### Project-level commands
Project commands live in both `.claude/commands/` and `.opencode/commands/`. Keep content identical or nearly so — adapt only tool-specific references.

### Instructions in CLAUDE.md only
Do NOT create an `AGENTS.md` unless content must genuinely differ between tools. OpenCode reads `CLAUDE.md` as fallback.

### Skills in .claude/skills/ only
Do NOT duplicate skills into `.opencode/skills/`. OpenCode discovers `.claude/skills/` via backward compatibility.

## Forbidden Patterns

### No AGENTS.md alongside CLAUDE.md
Creating `AGENTS.md` when `CLAUDE.md` suffices causes maintenance divergence. Only create it if OpenCode needs materially different instructions.

### No skill duplication
Never copy a skill into `.opencode/skills/` — this creates two copies to maintain with no benefit.

### No hardcoded Nix store paths
Commands and skills must not reference `/nix/store/...` paths, which change on every rebuild.

### Adding a New Global Command

1. Create the command file in `config/claude/commands/<name>.md`
2. Add two `home.file` entries in `flake.nix` within `mkUserConfig`:
   ```nix
   file.".claude/commands/<name>.md" = { source = ./config/claude/commands/<name>.md; force = true; };
   file.".config/opencode/commands/<name>.md" = { source = ./config/claude/commands/<name>.md; force = true; };
   ```
3. Rebuild: `darwin-rebuild switch --flake .#<hostname>`

### Promoting a Project Skill to Global

When a skill proves useful beyond a single project, promote it to global scope:

1. **Copy** the skill from the project's `.claude/skills/<name>/SKILL.md` to `config/claude/skills/<name>/SKILL.md`
2. **Generalize** — strip all project-specific references
3. **Add home.file entry** in `flake.nix` within `mkUserConfig`
4. **Rebuild**: `darwin-rebuild switch --flake .#<hostname>`

### Generalization Checklist

- [ ] No project-specific framework references (Rails, Stimulus, Express, etc.)
- [ ] No project-specific file paths or guide citations
- [ ] No project-specific case studies (generalize or remove)
- [ ] Examples use generic code patterns
- [ ] Verify with: `grep -i "project-name\|framework-name" config/claude/skills/<name>/SKILL.md`

### When to Revisit

Re-evaluate this approach if:
- OpenCode drops backward compatibility for `.claude/skills/` or `CLAUDE.md`
- OpenCode introduces a settings/hooks system worth configuring
- The tools diverge enough that shared commands no longer make sense
