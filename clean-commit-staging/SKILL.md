---
name: clean-commit-staging
description: "Prevents pre-staged files from other sessions contaminating commits. Auto-activates when committing in repos with parallel sessions, background agents, or hooks that stage files. Trigger keywords: pre-staged, unexpected commit, wrong files committed, staging area contamination, parallel session commit."
---

# Clean Commit Staging

`git commit` commits EVERYTHING in the staging area — not just what was just added. If another session staged 50 files via `git add` without committing, they all silently go into your next commit.

## Before Every Commit

```bash
git diff --cached --name-only
```

If unexpected files appear, unstage everything and re-stage only yours:

```bash
git reset HEAD
git add <your-specific-files>
git commit
```

**Primary contamination source**: parallel agents or background workers that `git add` files but don't commit before their context window ends.

## Optimization History

- **April 1, 2026**: Five-step optimizer pass 1. Deleted non-working Option 2, verbose Option 3, redundant anti-patterns, PARA-specific "When This Matters." 50 → 14 lines (72%).
