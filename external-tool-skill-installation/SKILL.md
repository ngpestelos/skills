---
name: external-tool-skill-installation
description: Install external tool skills (like Firecrawl) that expose AI-compatible skill files. Use when adding tools that provide `skills add` functionality or when the CLI's `init` command doesn't directly expose skills.
trigger: installing skills from external tools, firecrawl skills, skills add command, external CLI skills
---

# External Tool Skill Installation

Many modern CLI tools (like Firecrawl) expose AI-compatible skill files that can be installed into Claude Code/Hermes. This skill documents the correct installation pattern.

## Common Pattern

Many CLIs advertise `npx -y tool@latest init` but this often installs the CLI **without** the skills. Skills are installed separately via the `skills` package manager.

## Installation Steps

### 1. Check if the tool has skills

Look for:
- References to "skills" in the tool's README
- `skills add` commands in documentation
- Skill files in the tool's repository

### 2. Install skills (not just the CLI)

```bash
# Install the CLI (often not enough)
npx -y tool@latest init

# Install the actual skills (correct approach)
npx -y skills add <org>/<repo> --full-depth --global --all --yes
```

**Example with Firecrawl:**
```bash
# Wrong - only installs CLI
npx -y firecrawl-cli@latest init --all --browser

# Correct - installs 8 skills to ~/.agents/skills/
npx -y skills add firecrawl/cli --full-depth --global --all --yes
```

### 3. Locate installed skills

Skills are installed to:
```
~/.agents/skills/<skill-name>/
```

Each skill has a `SKILL.md` file:
```
~/.agents/skills/firecrawl/SKILL.md
~/.agents/skills/firecrawl-scrape/SKILL.md
~/.agents/skills/firecrawl-search/SKILL.md
```

### 4. Link to Hermes/Claude Code (if needed)

If skills aren't automatically available, symlink them:

```bash
# For Hermes/Claude Code
ln -s ~/.agents/skills/<skill-name> ~/.claude/skills/

# Or to the global skills repo
ln -s ~/.agents/skills/<skill-name> ~/src/skills/<category>/<skill-name>
```

## Flags Reference

| Flag | Purpose |
|------|---------|
| `--full-depth` | Install with full documentation |
| `--global` | Install globally |
| `--all` | Install to all detected agents |
| `--yes` | Skip confirmation prompts |
| `--agent <name>` | Target specific agent only |

## Important: Skills ≠ CLI Tool

Installing skills only installs the **AI-compatible skill definitions** (SKILL.md files), not necessarily the actual CLI tool. The skill files describe how to use the tool, but the executable may still need to be available.

### When the CLI isn't available

If you get `command not found` after installing skills, check for:

1. **Custom scripts**: Look for user-created wrappers like `.claude/scripts/firecrawl-fetch.py`
2. **Alternative CLIs**: The tool may have a different package name (e.g., `firecrawl-cli` vs `firecrawl`)
3. **Direct API usage**: Use the skill documentation to call APIs directly with curl/Python

### Using skills when CLI isn't available

If the skill loads but the `command not found`:

```bash
# Check for user-created wrapper scripts
python3 .claude/scripts/<tool>-fetch.py <args>

# Or call APIs directly using the skill's curl examples
```

### Credential issues with Hermes profiles

If skills load but can't find API keys, see **`hermes-profile-credential-resolution`** skill. Common issue: credentials are in `~/.hermes/profiles/<profile>/.env` but tools look in `~/.hermes/.env`.

Quick fix:
```bash
export API_KEY=$(grep "API_KEY" ~/.hermes/profiles/<profile>/.env | cut -d'=' -f2)
```

## Troubleshooting

### Skills not found after installation
- Check `~/.agents/skills/` directory exists
- Verify the tool actually exposes skills (not all do)
- Check the skill names with `ls ~/.agents/skills/`
- Link to `~/src/skills/` for Hermes: `ln -s ~/.agents/skills/<skill-name> ~/src/skills/`

### Skills not loading in Claude Code
- Ensure skills are in `~/.claude/skills/` or `~/src/skills/`
- Check for symlinks if using custom paths
- Restart Claude Code to reload skill registry

## Examples

### Firecrawl
```bash
npx -y skills add firecrawl/cli --full-depth --global --all --yes
```

Installs: `firecrawl`, `firecrawl-scrape`, `firecrawl-search`, `firecrawl-crawl`, `firecrawl-map`, `firecrawl-download`, `firecrawl-instruct`, `firecrawl-agent`

## Verification

```bash
# Check installed skills
ls ~/.agents/skills/

# Read a skill
head ~/.agents/skills/<skill-name>/SKILL.md
```

## See Also

- **`hermes-profile-credential-resolution`** — When skills can't find API keys due to Hermes profile-specific .env locations
