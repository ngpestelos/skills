---
name: nix-managed-plugin-workaround
description: "Workaround for installing Claude Code plugins when settings.json is a nix-managed symlink. Copies plugin skill files directly instead of using `claude plugin install`. Trigger keywords: plugin install, EACCES, nix symlink, settings.json readonly, plugin skill copy."
---

# Installing Claude Code Plugins on Nix-Managed Systems

When `~/.claude/settings.json` is a nix-darwin symlink, `claude plugin install` fails with `EACCES: permission denied`.

## Fix

1. **Clone marketplace** (one-time):
   ```bash
   git clone --depth 1 https://github.com/anthropics/claude-plugins-official.git /tmp/claude-plugins-official
   ```

2. **Inspect plugin type**:
   ```bash
   find /tmp/claude-plugins-official/plugins/<name>/ -type f
   ```
   - **Skill-only** (most common) → step 3
   - **Has .mcp.json** → also needs `claude mcp add` or dotfiles MCP config
   - **Has commands/** → also copy to dotfiles `.claude/commands/` source, then rebuild

3. **Copy skill with attribution** to skills repo:
   ```bash
   mkdir -p ~/src/skills/<category>/<name>
   cp /tmp/claude-plugins-official/plugins/<name>/skills/<name>/SKILL.md ~/src/skills/<category>/<name>/SKILL.md
   ```
   Add to frontmatter:
   ```yaml
   license: Apache-2.0
   origin: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/<name>
   author: Anthropic (support@anthropic.com)
   ```

4. **Activate**: Run `install.sh` or restart Claude Code. Won't appear in `claude plugin list` — loads as a regular skill. Updates require manual re-clone.

## Optimization History

- **March 18, 2026**: Five-step pass 1. 66 → 42 lines (36%).
- **April 1, 2026**: Five-step pass 2. Deleted discovery context (restates intro), allowed-tools. 42 → 30 lines (29%).
