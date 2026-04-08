# AGENTS.md

Skills are standalone SKILL.md files compatible with Claude Code, Cursor, VS Code Copilot, Gemini CLI, OpenCode, and Goose. Spec: [agentskills.io](https://agentskills.io).

## Commands

```bash
./check.sh                  # validate all skills
./check.sh <skill-name>     # validate one skill
./install.sh                # symlink skills into agent skills directory
./multi-repo-loader.sh      # load skills from multiple repos
```

## Repository Structure

Skills live flat at the top level — no category subdirectories:

- `<name>/SKILL.md` — single markdown file with YAML frontmatter
- `<name>/references/` — optional supplementary files
- `.claude-plugin/marketplace.json` — plugin registry
- `check.sh` — spec validation (name, description, line count, version sync)
- `install.sh` — idempotent symlinker, cleans stale links

## Skill File Format

```yaml
---
name: lowercase-hyphenated    # must match directory name, 1-64 chars
description: "..."            # <= 1024 chars
metadata:
  version: "1.0.0"            # semver, must match marketplace.json
  category: rails             # optional: rails, nix, claude-code, frontend, security, debugging, workflow, general
---
```
Body: < 500 lines.

## Key Constraints

- **Name must match directory**: `foo-bar/SKILL.md` must have `name: foo-bar`
- **Name format**: lowercase alphanumeric + hyphens; no consecutive hyphens; must not start or end with a hyphen
- **Version sync required**: `SKILL.md` frontmatter version must match `.claude-plugin/marketplace.json` version
- **No non-standard frontmatter keys** outside `metadata:`

## Workflow

**Update**: Edit SKILL.md → `./check.sh <name>` → bump version in SKILL.md and marketplace.json.

**Add**: Create `<name>/SKILL.md` → `./check.sh <name>` → add to marketplace.json → add row to README.md.

## Versioning

- Patch: typo/wording fixes
- Minor: new patterns, examples, sections
- Major: breaking methodology/structure changes
