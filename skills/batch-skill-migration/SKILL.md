---
name: batch-skill-migration
description: "Guides batch migrating Claude Code skills between repositories with redaction and coordinated multi-repo commits. Auto-activates when moving skills to a public repo or synchronizing marketplace.json. Trigger keywords: migrate skills, batch migration, redact skill, marketplace.json, public skills repo, move skills."
allowed-tools: Read, Grep, Glob, Bash
---

# Batch Skill Migration Between Repos

Migrate skills from a private repo to a public skills repo. Frontmatter must comply with the Agent Skills spec — run `/skills-audit` to validate.

## Redaction Checklist

Before publishing, scrub personal references:

- Usernames → generic names (`ngpestelos` → `primary-user`)
- Home paths → `$USER` or `$HOME` (`/Users/ngpestelos` → `/Users/$USER`)
- Private project names → remove or genericize
- Email addresses in examples → generic
- Hostnames → `<hostname>`

## Sequence

1. **Classify** — skills referencing private projects stay in dotfiles
2. **Redact** — apply checklist above to each skill
3. **Write to target repo** — create `skills/<name>/SKILL.md`, add marketplace.json entry (copy existing entry as template), add to README.md table
4. **Verify** — line counts under 500, `/skills-audit` passes
5. **Clean source repo** — remove skill directories, remove `home.file` entries from flake.nix, update source README
6. **Commit target first, then source** — ensures skills exist before source deletes them

After committing: run `install.sh` to symlink, then `darwin-rebuild switch` to remove stale home.file entries.

## Pitfalls

- **Stale home.file entries** — old nix-darwin skill entries conflict with install.sh symlinks; always remove from flake.nix
- **Private skills in public repo** — skills referencing private projects (OpenClaw, etc.) must stay in dotfiles

## Discovery Context

- **Date**: 2026-03-18
- **Scenario**: Migrated 17 skills from ~/src/dotfiles to ~/src/skills/. Cleaned frontmatter, redacted personal info, updated marketplace.json (28→45 entries), coordinated commits across both repos.
