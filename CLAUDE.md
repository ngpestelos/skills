# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A collection of [Agent Skills](https://agentskills.io) distributed as a Claude Code plugin. Skills are standalone SKILL.md files that follow the Agent Skills specification and work across multiple AI coding tools (Claude Code, Cursor, VS Code Copilot, Gemini CLI, OpenCode, Goose).

## Commands

```bash
# Validate all skills against the Agent Skills spec
./check.sh

# Validate a single skill
./check.sh <skill-name>

# Install all skills via symlink to ~/.claude/skills/
./install.sh

# Load skills from multiple GitHub repos (config: ~/.claude/skill-sources.txt)
./multi-repo-loader.sh
```

## Repository Structure

- `skills/<name>/SKILL.md` — Each skill is a single markdown file with YAML frontmatter
- `skills/<name>/references/` — Optional supplementary files (only `database-migration-termination-safety` uses this)
- `.claude-plugin/marketplace.json` — Plugin registry for individual skill installation
- `check.sh` — Spec validation (name format, description length, body size, version sync)
- `install.sh` — Idempotent symlinker, also cleans stale links
- `multi-repo-loader.sh` — Multi-repo skill aggregator (untracked, not yet committed)

## Skill File Format

Each SKILL.md has this structure:
```yaml
---
name: lowercase-hyphenated    # must match directory name, 1-64 chars
description: "..."             # <= 1024 chars
metadata:
  version: "1.0.0"            # semver, must match marketplace.json
---
```
Body must be < 500 lines and < 5000 estimated tokens.

## Key Constraints

- **Name must match directory**: `skills/foo-bar/SKILL.md` must have `name: foo-bar`
- **No consecutive hyphens** in skill names
- **Version sync required**: `SKILL.md` frontmatter version must match `.claude-plugin/marketplace.json` version
- **No non-standard frontmatter keys** outside `metadata:`

## Workflow for Changes

**Updating a skill**: Edit SKILL.md, run `./check.sh <skill-name>`, bump version in both SKILL.md and marketplace.json.

**Adding a skill**: Create `skills/<name>/SKILL.md`, run `./check.sh <name>`, add entry to marketplace.json, add row to README.md skills table.

Use `/skills-audit <skill-name>` for deeper spec compliance checking beyond what `check.sh` covers.

## Versioning

- Patch: typo/wording fixes
- Minor: new patterns, examples, sections
- Major: breaking methodology/structure changes
