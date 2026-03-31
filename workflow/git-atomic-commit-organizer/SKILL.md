---
name: git-atomic-commit-organizer
description: Systematically analyze uncommitted changes and organize them into logical, atomic commits following best practices. Auto-activates when organizing git commits, multiple uncommitted changes, git cleanup, atomic commits. Trigger keywords: prepare commits, organize commits, git cleanup, atomic commits, logical commits, uncommitted changes, git organization, commit organization, multiple changes.
metadata:
  version: 1.0.0
---

# Git Atomic Commit Organizer

Principles for organizing messy uncommitted changes into clean, atomic commits. **For execution, use `/commit`.**

## Atomic Commits

Each commit = one logical change that is:
- Single purpose (feature, fix, refactor, docs, config)
- Complete and coherent (no half-finished work, no accidental sensitive data)
- Independently revertible

## Grouping Boundaries

Organize files by natural boundaries:
- **Feature code** — new functionality, business logic
- **Tests** — test files accompanying feature work
- **Documentation** — README, docs, changelogs
- **Configuration** — build config, CI/CD, linter rules, dependencies
- **Assets** — images, static files, fonts
- **Refactoring** — code moves, renames, restructuring without behavior change

Within each type, group by module/feature. Keep implementation and its tests together.

## Don't

- Mix unrelated changes in the same commit
- Commit incomplete work ("WIP" commits)
- Use vague messages ("Update files", "Fix stuff")
- Create huge commits with 20+ unrelated files
- Use `git add .` or `git add -A` (stage specific files)

## Example

```bash
git add src/api/retry.js src/api/client.js
git commit -m "$(cat <<'EOF'
Add retry logic for flaky API connections

Prevents transient network failures from crashing the import job.
Uses exponential backoff with 3 retries.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```
